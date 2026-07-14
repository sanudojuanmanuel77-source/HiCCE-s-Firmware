
#include <stdio.h>
#include "xparameters.h"
#include "netif/xadapter.h"
#include "platform_config.h"
#include "xil_printf.h"


#include "xaxidma.h"
#include "xgpiops.h" //Includes necesarios para el uso del GPIO y DMA

#include <math.h>
#include <stdbool.h> //false no false.

void network_thread();
void echo_application_thread(void *);
void XADC_sending(void *param);
void lwip_init();

#define SERVER_ADDR "192.168.1.10"  // Direccón IP del servidor en formato de cadena
#define SERVER_PORT 7           // Puerto del servidor

#define THREAD_STACKSIZE 2048 //2048??

#define NCHAN   128 // Número de canales emitidos.
#define MICROVOLTS 1e6f // Conversion a microvoltios del dato a enviar.
#define GAIN 200		// Ganancia del Intan RHA2132.

#define SAMPLE_COUNT 512 //Número de muestras enviadas... Máximo 2^25 = 33.554.431 //Definido en el DMA...

#define LSB 38.15f

//En este arreglo de memoria, declarado como variable globla, recibiremos los datos del las interfaces SPI de los AD7982 de los Intan RHA2132 que envia el DMA.
 u16 DataBuffer[SAMPLE_COUNT + 8] __attribute__((aligned(4)));

 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	 	  //Se requiere que el buffer de memoria target del DMA este alineado con una direccion de memoria divisible por 4.
																	 // Ademas se hace al buffer 16 bytes mas grande de lo requerido, ya que se necesita invalidar el cache
																	//  en un rango de memoria un poco mas grande. Si no se hace, se corre el riesgo de poblemas con el cache causados por el
																   //   final del buffer no alineado con la linea del cache.


#include "xaxidma_hw.h"

#define DMASR_HALTED  (1u<<0)
#define DMASR_IDLE    (1u<<1)
#define DMASR_INT_ERR (1u<<4)
#define DMASR_SLV_ERR (1u<<5)
#define DMASR_DEC_ERR (1u<<6)
#define DMASR_IOC_IRQ (1u<<12)
#define DMASR_DLY_IRQ (1u<<13)
#define DMASR_ERR_IRQ (1u<<14)



float g_state[NCHAN]; //Arreglo global donde se guardan los estados correspondientes el filtro HPF para el off set y el DC level.
 int   g_seeded = 0;	//bandera del arreglo g_state. Si es inicio de la transmision, se inyecta el valor inicial como valor de state para reducir la diferencia inicial.
float fc_hz = 0.5f;		// Frecuencia de corte del filtro digital. Off-set y 1,235 V.
float fs_hz = 15394;  //SPI FSM 2030 ns entre muestras... TEST BENCH... FLANCO ENTRE DATA READY O CNV! == 2030 ns.
float A,B; //Filter HPF  Parameters.

XGpioPs GpioInstance; //Instancia PS GPIO
static XAxiDma AxiDmaInstance; //Instancia AXI DMA  "la forma sencilla" que brinda Xilinx de configurar los perfifericos o recuros del Zynq , gracias al BSP, y los drivers que pone a disposición.



static float (*Xadc_RawToVoltageFunc)(u16 RawData); //Puntero a la funcion para convertir la medicion a volts
													//podria cambiarse si cada canal requiere una conversion distinta
												    // por ejempllo si una tiene un divisor resistivo para ajstar el rango de 0 V a 1 V



static void dbg_dump_emio54(void) {
    int dir = XGpioPs_GetDirectionPin(&GpioInstance, 54);        // 1=OUT, 0=IN
    int oe  = XGpioPs_GetOutputEnablePin(&GpioInstance, 54);     // 1=habilitado como salida
    u32 b2  = XGpioPs_Read(&GpioInstance, 2);                    // registro de datos del banco 2
    int val = XGpioPs_ReadPin(&GpioInstance, 54);                // valor del pin

    xil_printf("[GPIO] EMIO[0]=pin54  dir=%s  oe=%d  bank2=0x%08lx  pin=%d\r\n",
               dir ? "OUT" : "IN", oe, (unsigned long)b2, val);
}

// Initialize the GPIO subsystem
static int GPIOInitialize()
{
	XGpioPs_Config *GpioConfig; // declaracion de puntero GpioConfig del la estrcutura XGpioPs_Config
	XStatus Status;				//declaracion variable tipo XStatus, para menejo de errores.

	GpioConfig = XGpioPs_LookupConfig(XPAR_PS7_GPIO_0_DEVICE_ID); // Busca la configuracion del EMIO GPIO en xparameters.h
	if(GpioConfig == NULL) {
		xil_printf("XGpioPS LookupConfig failed! terminating\n");

		return XST_FAILURE;	 //si no es capaz de encontrar la configuracion, devuelve error.
	}

	//Inicializa el EMIO GPIO en base a la configuracion encontrada.
	Status = XGpioPs_CfgInitialize(&GpioInstance, GpioConfig, GpioConfig->BaseAddr);
	if(Status != XST_SUCCESS) {
		xil_printf("XGpioPs_CfgInitialize failed! terminating");

		return XST_FAILURE; // Devuelve error si no le fue posible inicialiar el GPIO
	}

	/*Se inicializa el GPIO. Sera la seÃƒÂ±al CONN  de la FSM SPI. indicara si hay o no conexion al servidor a toda la logida de adquisicion de datos de la PL
	 * mediante el PIN 54 del GPIO */



	//Se configura al  pin del EMIO 54 como salida.
	XGpioPs_SetDirection( &GpioInstance, 2 /*Bank 2*/, 1 );



	// Habilita al pin EMIO 54 del banco 2 como salida.
	XGpioPs_SetOutputEnable( &GpioInstance, 2 /*Bank 2*/, 1 );

	//Inicializa valor de CONN en 0...
	XGpioPs_WritePin(&GpioInstance, 54, 1);




	return 0;
} // GPIOInitialize



//Convierte un valor RAW (crudo) obtenido del AD7182 , tras muestrear MUX_OUT  del INTAN RHA2132. Provienen 16 bits sin signo. bit 18 de signo eliminado en PL , ya que es siempre 0. bit 0, ruidoso elminado.
//acorde a la funcion de tranferencia
float Xadc_RawToVoltageVPVN(u16 RawData)
{

								//---> CALCULO DE ENOB...
	//const float VREF = 2.5f;
	//return ((float)RawData * ( VREF /65536.0)); //Convierte el valor digital a voltaje. 1 LSB equivale a 2,5V/65536 .El rango de MUX_OUT va de (2,235V  a 235 mV) +5 mv en Intan y -5 mv En intan.
												// Un bit equivale a 38,14 micro volt EN TEORÃƒï¿½A. hay que dividir por 200 de amplificaion original...  190 nV ?? --> calcular/obtener --> ENOB.
	//return ((float)RawData * LSB);

	const u32 VREF = 2500000;

	return ((int32_t)RawData * ( VREF /65536));
	//EL ADC USA DE REF 2,5 V Y POSEE 16 BITS... REGULADOR ADR381
	//DEJAR EL VOLTAJE CRUDO DE MUX OUT QUE OSCILE ENTRE 2,235 V Y -0,235V CON BASELINE DE 1,235 V... TRAS FILTRAR (RSTAR BASE LINE Y OFFSET , AHI DIVIDIR POR 200 Y 1E6 A MICROVOLTS.)
	//EL SIGNO DE LA MUESTRA APARECERA TRAS LA RESTA, AQUI SON TODOS POSITIVOS...
	// Convierte el valor digital a voltaje. En este caso, el divisor es 65535 debido al promediado

}

//Funcion para el filtrado de off set del Intan y el nivel de DC que introduce en la salida en MUX_OUT.
//Filtro IIR de primer orden pasa altos. Frecuencia de corte = 0,5 Hz. Frecuencai dec orte Intan = 1 Hz.


/*int Filter_BaseLine_G200(float unfiltered_data[]){


	if (g_seeded==0) { //es la primera vez que se ejectua! inicia la transmision, primer badge
	        for (int c = 0; c < NCHAN; ++c)
	        	g_state[c] = unfiltered_data[c];  // k0 de cada canal

	         A = expf(-2.0f * 3.14159265358979323846f * (fc_hz / fs_hz));
	         B = 1.0f - A;



	        	g_seeded = 1;
	    }


	 for (int i = 0; i < SAMPLE_COUNT; ++i) {
	        int   c = i % NCHAN;      // canal 0..127
	        float x = unfiltered_data[i];       // unidades en VOLTS. Salida cruda de mux out FILTRADA.
	        float y = x - g_state[c]; // salida HPF
	        g_state[c] = B*x + A*g_state[c];
	        unfiltered_data[i] = y;
	    }

	 for( int n=0;n< SAMPLE_COUNT;n++){

		 unfiltered_data[n] = unfiltered_data[n]*(MICROVOLTS/GAIN);

	 }

	 return 0;


}*/



//Network Interfaces = netif... Interface por la que se establecera la conexion con el servidor LSL y se enviaran los datos.

static struct netif server_netif;
struct netif *echo_netif;





static int DMAInitialize()
{
	XAxiDma_Config *cfgptr; //Puntero para la configuraciÃƒÂ³n del AXI DMA
	XStatus Status;			//Variable para menejar el estado

	//Obtiene la configuracion del AXI DMA dede xparameters.h
	cfgptr = XAxiDma_LookupConfig(XPAR_AXI_DMA_0_DEVICE_ID);

	if(cfgptr == NULL){

		xil_printf("XAxiDma_LookupConfig failed! terminatig\n");
		return XST_FAILURE; //Devuelve error si no encunetra la configuraciÃƒÂ³n
	}

	//Inicializar el AXI DMA con la configuracion obtenida
	Status = XAxiDma_CfgInitialize(&AxiDmaInstance, cfgptr);

	if (Status != XST_SUCCESS){
		xil_printf("XAxiDma_CfgInitialize failed! terminating\n");
		return XST_FAILURE; //Devuelve error si la inicialiaciÃƒÂ³n falla
	}

	//Desactiva las interrupciones del DMA, ya que no se usan
	XAxiDma_IntrDisable(&AxiDmaInstance, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
	XAxiDma_IntrDisable(&AxiDmaInstance, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

	return 0; //indica que la inicializacion del DMA fue existosa.

} //DMAInitialize


static inline void dump_s2mm_status(const char* tag)
{
    u32 sr = XAxiDma_ReadReg(AxiDmaInstance.RegBase,
                             XAXIDMA_RX_OFFSET + XAXIDMA_SR_OFFSET);
    u32 cr = XAxiDma_ReadReg(AxiDmaInstance.RegBase,
                             XAXIDMA_RX_OFFSET + XAXIDMA_CR_OFFSET);
    xil_printf("[%s] S2MM: SR=0x%08lx CR=0x%08lx  Halted=%d Idle=%d  IOC=%d Dly=%d ErrIRQ=%d  Int=%d Slv=%d Dec=%d\r\n",
        tag, (unsigned long)sr, (unsigned long)cr,
        !!(sr&DMASR_HALTED), !!(sr&DMASR_IDLE),
        !!(sr&DMASR_IOC_IRQ), !!(sr&DMASR_DLY_IRQ), !!(sr&DMASR_ERR_IRQ),
        !!(sr&DMASR_INT_ERR), !!(sr&DMASR_SLV_ERR), !!(sr&DMASR_DEC_ERR));
}

static inline void clear_s2mm_irqs(void)
{
    XAxiDma_WriteReg(AxiDmaInstance.RegBase,
                     XAXIDMA_RX_OFFSET + XAXIDMA_SR_OFFSET,
                     DMASR_IOC_IRQ | DMASR_DLY_IRQ | DMASR_ERR_IRQ);
}




int ReceiveData(void)
{
    //u16 *payload  = &DataBuffer[4];
    const u32 RX_BYTES = SAMPLE_COUNT * sizeof(u16);

    // 0) Limpiar IRQs latcheadas del ciclo anterior
    clear_s2mm_irqs();
  //  dump_s2mm_status("PRE");

    // 1) Cache: flush de destino ANTES del S2MM
    Xil_DCacheFlushRange((UINTPTR)DataBuffer, RX_BYTES);

    // 2) Programar transferencia
    XStatus s = XAxiDma_SimpleTransfer(&AxiDmaInstance,
                                       (UINTPTR)DataBuffer,
                                       RX_BYTES,
                                       XAXIDMA_DEVICE_TO_DMA);
    if (s != XST_SUCCESS) {
        xil_printf("[RX] SimpleTransfer FAILED\r\n");
        return XST_FAILURE;
    }



    // 3) Esperar fin con timeout
    const TickType_t t0 = xTaskGetTickCount();
    while (XAxiDma_Busy(&AxiDmaInstance, XAXIDMA_DEVICE_TO_DMA)) {
        // si tu fuente AXIS no manda TLAST, esto nunca va a salir
        if ((xTaskGetTickCount() - t0) > pdMS_TO_TICKS(200)) {
            xil_printf("[RX][TO] DMA no completó en 200 ms\r\n");
            dump_s2mm_status("TIMEOUT");

            // Limpio flags; si hay error, reset canal
            clear_s2mm_irqs();

            // Si hubo ErrIRQ o no sale de Busy, reset al core
            XAxiDma_Reset(&AxiDmaInstance);
            // esperar a que termine el reset
            while (!XAxiDma_ResetIsDone(&AxiDmaInstance)) { /*spin*/ }

            return XST_FAILURE;
        }
        //taskYIELD();
    }

    // 4) Invalidate para poder leer lo que escribió el DMA
    Xil_DCacheInvalidateRange((UINTPTR)DataBuffer, RX_BYTES);


    return XST_SUCCESS;
}





void
print_ip(char *msg, ip_addr_t *ip)
{
	xil_printf(msg);
	xil_printf("%d.%d.%d.%d\n\r", ip4_addr1(ip), ip4_addr2(ip),
			ip4_addr3(ip), ip4_addr4(ip));
}

void
print_ip_settings(ip_addr_t *ip, ip_addr_t *mask, ip_addr_t *gw)
{

	print_ip("Board IP: ", ip);
	print_ip("Netmask : ", mask);
	print_ip("Gateway : ", gw);
}


int main()
{
	//// Crea una tarea para manejar la red y sus subsistemas, ademÃƒÂ¡s  la tarea que crea e inicia el servidor en modo escucha.
	sys_thread_new("NW_THREAD", (void(*)(void*))network_thread, 0,
	                THREAD_STACKSIZE,
	                DEFAULT_THREAD_PRIO);

	// Inicia el scheduler de tareas de FreeRTOS. A partir de este punto, las tareas comienzan a ejecutarse.
	vTaskStartScheduler();

	//Si nada falla, el main nunca deberia alcanzar este punto
	return 0;
}

void network_thread(void *p)
{
    struct netif *netif;

    /* La direccion de MAC de la placa. Este valor es unico de cada dispositivo */
    unsigned char mac_ethernet_address[] = { 0x00, 0x0a, 0x35, 0x00, 0x01, 0x02 };
    ip_addr_t ipaddr, netmask, gw;


    lwip_init(); //Inicializacion de lwIP

    netif = &server_netif;

    xil_printf("\r\n\r\n");
    xil_printf("-----lwIP Socket Mode HiCCE Application ------\r\n");


    /* Inicia la IP, mascara de red y gateaway a usar*/
    IP4_ADDR(&ipaddr,  192, 168, 1, 10);
    IP4_ADDR(&netmask, 255, 255, 255,  0);
    IP4_ADDR(&gw,      192, 168, 1, 1);


    /* print out IP settings of the board */


    print_ip_settings(&ipaddr, &netmask, &gw);
    /* Imprime los parametros dados */


    //AÃƒÂ±ade la interfaz de red a la netif_list , y la configura como default.
    if (!xemac_add(netif, &ipaddr, &netmask, &gw, mac_ethernet_address, PLATFORM_EMAC_BASEADDR)) {
	xil_printf("Error adding N/W interface\r\n");
	return;
    }

    netif_set_default(netif);

    /* Especifica que la red esta activa*/
    netif_set_up(netif);

    // inicializacion de subsistemas y


    xil_printf("***** HiCCE THREAD STARTED *****\n");
    xil_printf("\r \n");
    xil_printf("will connect to the network address %s:%d\n", SERVER_ADDR, SERVER_PORT);
    xil_printf("\r \n");
    xil_printf("samples per DMA transfer: %d\n", SAMPLE_COUNT);



    // Inicializa los subsistemas a utilizar
    	if( GPIOInitialize() == XST_FAILURE ){
    		vTaskDelete(NULL);

    	}
    	if( DMAInitialize()  == XST_FAILURE ){
    		vTaskDelete(NULL);
    	}

    	 xil_printf("\r \n");

    	xil_printf("GPIO AND DMA were configured successfully\n");

    /* start packet receive thread - required for lwIP operation */
    sys_thread_new("xemacif_input_thread", (void(*)(void*))xemacif_input_thread, netif,
            THREAD_STACKSIZE,
            DEFAULT_THREAD_PRIO);



    sys_thread_new("echod", echo_application_thread, 0, THREAD_STACKSIZE, DEFAULT_THREAD_PRIO);
    vTaskDelete(NULL);

    return;
}



