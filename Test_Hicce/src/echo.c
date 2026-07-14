
#include <stdio.h>
#include <string.h>

#include "lwip/sockets.h"
#include "netif/xadapter.h"
#include "lwipopts.h"
#include "xil_printf.h"
#include "FreeRTOS.h"
#include "task.h"
#include <stdbool.h>
#define THREAD_STACKSIZE 1024
#define THREAD_STACKSIZE_SEND 2048


#include "xil_types.h"


#include <stdio.h>
#include "xparameters.h"
#include "netif/xadapter.h"
#include "platform_config.h"
#include "xil_printf.h"

//#include "xsysmon.h"
#include "xaxidma.h"
#include "xgpiops.h" //Includes necesarios para el uso del XADC y DMA


#include <stdbool.h> //false no false


u16_t echo_port = 7;

#include "math.h"
#include "stdint.h"
#include "stdlib.h"

extern size_t xPortGetFreeHeapSize(void);

extern int ReceiveData();
extern float Xadc_RawToVoltageVPVN(u16 RawData);
extern int Filter_BaseLine_G200(float unfiltered_data[]);
//EXTERN DEL FILTERED!!
#define SAMPLE_COUNT 512
#define NCHAN 128
float convertedData[SAMPLE_COUNT];

#define MICROVOLTS 1e6f
#define GAIN 200

// common.h
extern XGpioPs GpioInstance;
extern int g_seeded;
extern float A,B;
extern float g_state[NCHAN];

extern u16 DataBuffer[SAMPLE_COUNT + 8];


s32 TxBuffer[SAMPLE_COUNT];


static void DumpU16(const u16 *buf, int count)
{
    for (int i = 0; i < count; ++i) {
        xil_printf("%03d:%04x%s", i, buf[i],
                   ((i & 0x0F) == 0x0F) ? "\r\n" : " ");
    }
    xil_printf("\r\n");
}

static void dbg_dump_emio54(void) {
    int dir = XGpioPs_GetDirectionPin(&GpioInstance, 54);        // 1=OUT, 0=IN
    int oe  = XGpioPs_GetOutputEnablePin(&GpioInstance, 54);     // 1=habilitado como salida
    u32 b2  = XGpioPs_Read(&GpioInstance, 2);                    // registro de datos del banco 2
    int val = XGpioPs_ReadPin(&GpioInstance, 54);                // valor del pin

    xil_printf("[GPIO] EMIO[0]=pin54  dir=%s  oe=%d  bank2=0x%08lx  pin=%d\r\n",
               dir ? "OUT" : "IN", oe, (unsigned long)b2, val);
}



void XADC_sending(void *param){

	int sock  = (int)param;

	//xil_printf("Conexion aceptada, iniciando adquicion de XADC\n");

	int nwrote;

	struct sockaddr client_address;
	socklen_t client_length;


	bool primed = false;

	//ACA COMENZARIA EL LOOP SIN FIN SIEMPRE Y CUANDO HAYA CONEXION !!!!!
	//xil_printf("Esperando al DMA \r \n");
	while(1){

		if (!primed) {
		        // 1) PRIMING: armá y recibí un batch, pero NO lo mandes al cliente
		        int rc = ReceiveData();                 // intenta 1
		        if (rc != XST_SUCCESS) {
		            xil_printf("[prime] rearmando S2MM...\r\n");
		            vTaskDelay(pdMS_TO_TICKS(5));       // breve respiro
		            rc = ReceiveData();                 // intenta 2 (sin cerrar socket)
		            if (rc != XST_SUCCESS) {
		                xil_printf("[prime] falló 2 veces, cerrando\r\n");
		                close(sock);
		                vTaskDelete(NULL);
		            }
		        }
		        primed = true;
		       // xil_printf("NO FUIMO PAL LOBBY\r\n");// descartamos este primer lote y seguimos
		        continue;               // volvemos al while: ahora sí a flujo normal
		    }






	if(ReceiveData() == XST_FAILURE){ //como esta en modo continuo de adquisicion... ya esta tomando todo el tiempo una mumestra, es cuestion de sacarle 1000 muestras que se producen ahi, y la interfaz axi 4 stream del xadc wizard se va a mimir.


		 //   for (int i=0; i<SAMPLE_COUNT; ++i) convertedData[i] = 1.234f;
		   // send(sock, convertedData, sizeof(convertedData), 0);
		    //continue;


		xil_printf("Error al recibir datos del XADC \r \n");
		close(sock);
		vTaskDelete(NULL); // Cierra la conexion y borra la tarea si falla la recepcion
	}


//	DumpU16(DataBuffer, SAMPLE_COUNT+8);
	u16 *payload = &DataBuffer;



	for (int m = 0; m < SAMPLE_COUNT; m++) {
		    TxBuffer[m] = (int32_t)payload[m]; // casteo seguro a int32
		}




	for(int n=0;n<SAMPLE_COUNT;n++){
		TxBuffer[n]=Xadc_RawToVoltageVPVN(TxBuffer[n]);
	}
	//float *payload = &DataBuffer[4];
	//DumpU16(payload, SAMPLE_COUNT);                 // NO +8






	//for(int m= 0; m<SAMPLE_COUNT; m++){
		//payload[m] = payload[m]*200;
//	}


	//xil_printf("Fin del DMA \r \n");
	nwrote = send(sock, TxBuffer, SAMPLE_COUNT*sizeof(int32_t), 0);
	//Convierte los datos crudos del XADC a voltaje
/*	for (int i = 0; i < SAMPLE_COUNT; i++){

		convertedData[i] = Xadc_RawToVoltageVPVN(DataBuffer[i]); // Obtenemos el valor de voltaje de MUX_OUT de cada intan en cada moemento...

	} */
//	DumpU16(convertedData, SAMPLE_COUNT);

	//Filtramos Baseline y off set. divisior por 200 y convertivimos a unidades de microvolts..

/*	if(Filter_BaseLine_G200(convertedData)!=0){
			xil_printf("Error al filtrar datos");
			close(sock);
			vTaskDelete(NULL);
	} else { xil_printf("filtrado con exito \r");} */

	//Envia los datos convertidos al cliente a traves de lwIP
	//nwrote= send(sock,convertedData,sizeof(convertedData),0);
	//nwrote= send(sock,DataBuffer,sizeof(convertedData),0);
	//Verifica si la transmision fue exitosa
	if(nwrote < 0){

		xil_printf("Error al enviar datos al cliente\n");

		//SE PERDIO LA CONEXIÓN

			XGpioPs_WritePin( &GpioInstance, 54, 0 ); //CONN A CERO, TODO A IDLE, RST INTERNO...
		  	g_seeded = 0;
		  	close(sock); //lwIP_close?
		  	xil_printf("Cerrando conexion\n");
		  	vTaskDelete(NULL);

	} /*else {
		xil_printf("Datos enviados correctamente (%d bytes) \n",nwrote);
	} */

	//xil_printf("Se viene el delay papaaa \r \n");

	//vTaskDelay(5);

	//taskYIELD();

	}

	//PREGUNTAMOS ¿esta abierta la conexion? si, repetir todo lo anterior... NO? CONN A 0, flag filtro a 0, cerrar sock, elimintar tarea




}






void echo_application_thread()
{
	int sock, accepted_sock;
	int size;

	struct sockaddr_in address; //estructuras definidas por lwIP

	struct sockaddr client_address;



	socklen_t client_length;

	TaskHandle_t xEchoTask;

	//Inicializa la estructura de la direccion en cero
	memset(&address, 0, sizeof(address));

	//Crea un socket TCP, indicado por SOCK_STREAM
	if ((sock = lwip_socket(AF_INET, SOCK_STREAM, 0)) < 0)
		return;

	//Configura la direccion del socket (IP, puerto)
	address.sin_family = AF_INET;
	address.sin_port = htons(echo_port);
	address.sin_addr.s_addr = INADDR_ANY;

	 xil_printf("\r \n");
	xil_printf("biding socket to port %d\n", echo_port);

	//Asigna el socket a la direccion y puerto configurado
	if (lwip_bind(sock, (struct sockaddr *)&address, sizeof (address)) < 0)
		return;

	//Configura el socket para estar en modo escucha. Espera por conexiones
	lwip_listen(sock, 0);

	client_length = sizeof(client_address);
	xil_printf("\r \n");

	xil_printf("Infinite loop waiting of conections\n", echo_port);
	//Bucle principal: espera y acepta coenxiones
	while (1) {

		//El socket queda en "hold" hasta que haya una conexion entrante
		if ((accepted_sock = lwip_accept(sock,(struct sockaddr *)&client_address, (socklen_t *)&client_length)) > 0) {

				XGpioPs_WritePin( &GpioInstance, 54, 1 );  //CONN EN 1!!!! QUE LA SPI SE ENTERE QUE TIENE CONEXION Y PRODUZCA DATOS....
				xil_printf("CONN ESTA EN !!!!\r\n");

				dbg_dump_emio54();






			//Crea la nueva tarea para manejar el envio de datos del XADC
			xTaskCreate(XADC_sending,"XADC_sending",THREAD_STACKSIZE_SEND, (void*)accepted_sock, DEFAULT_THREAD_PRIO, &xEchoTask);
			xil_printf("Creanto tarea de envio de datos\n");
			xil_printf("Heap libre: %u bytes\r\n", (unsigned)xPortGetFreeHeapSize());
		}
	   }
	}


