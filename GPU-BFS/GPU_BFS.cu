
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <cuda.h>
#include <device_functions.h>
#include <cuda_runtime_api.h>
#include<time.h>

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <conio.h>
#define NUM_NODES 6
#define num_blks 1


typedef struct
{
	int start;     // Index of first adjacent neigbour node in d_adjLists	
	int length;    // Number of neighbour nodes 
} Node;

__global__ void CUDA_BFS_KERNEL(Node* d_VertixArray, int* d_adjLists, bool* d_front, bool* d_Visited, bool* done)
{

	int id = threadIdx.x + blockIdx.x * blockDim.x;
	if (id > NUM_NODES)
		*done = false;
	

	if (d_front[id] == true && d_Visited[id] == false)
	{
		 printf("%d ", id); 	
		 d_front[id] = false;
		 d_Visited[id] = true;
		__syncthreads();
		//	int k = 0;
			//int i;
		int start = d_VertixArray[id].start;
		int end = start + d_VertixArray[id].length;
		for (int i = start; i < end; i++)
		{
			int nid =  d_adjLists[i];

			if (d_Visited[nid] == false && d_front[nid] == false && d_Visited[id] == true)
			{
				//printf("%d", nid);
				d_front[nid] = true;
				*done = false;
			}

		}

	}

}


int main()
{
	Node Vertex[NUM_NODES];
	int edges[15];
	cudaEvent_t start, stop;
	Node* d_VertexArray;
	int* d_adjLists;
	bool done;
	bool* d_done;
	bool* d_front;
	bool* d_Visited;



	Vertex[0].start = 0;
	Vertex[0].length = 2;

	Vertex[1].start = 2;
	Vertex[1].length = 3;

	Vertex[2].start = 5;
	Vertex[2].length = 3;

	Vertex[3].start = 8;
	Vertex[3].length = 3;

	Vertex[4].start = 11;
	Vertex[4].length = 2;

	Vertex[5].start = 13;
	Vertex[5].length = 2;

	edges[0] = 1;
	edges[1] = 2;
	edges[2] = 0;
	edges[3] = 3;
	edges[4] = 0;
	edges[5] = 0;
	edges[6] = 3;
	edges[7] = 5;
	edges[8] = 1;
	edges[9] = 2;
	edges[10] = 4;
	edges[11] = 3;
	edges[12] = 5;
	edges[13] = 2;
	edges[14] = 4;

	bool front[NUM_NODES] = { false };
	bool visited[NUM_NODES] = { false };


	int source = 0;
	front[source] = true;

	 
	cudaMalloc((void**)&d_VertexArray, sizeof(Node) * NUM_NODES);
	cudaMemcpy(d_VertexArray, Vertex, sizeof(Node) * NUM_NODES, cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_adjLists, sizeof(Node) * NUM_NODES);
	cudaMemcpy(d_adjLists, edges, sizeof(Node) * NUM_NODES, cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_front, sizeof(bool) * NUM_NODES);
	cudaMemcpy(d_front, front, sizeof(bool) * NUM_NODES, cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_Visited, sizeof(bool) * NUM_NODES);
	cudaMemcpy(d_Visited, visited, sizeof(bool) * NUM_NODES, cudaMemcpyHostToDevice);

	cudaMalloc((void**)&d_done, sizeof(bool));

	//int count = 0;
	printf("Breadth-First Search: ");
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);
	do {
		//count++;
		done = true;
		cudaMemcpy(d_done, &done, sizeof(bool), cudaMemcpyHostToDevice);
		CUDA_BFS_KERNEL << <num_blks, NUM_NODES >> > (d_VertexArray, d_adjLists, d_front, d_Visited, d_done);
		cudaMemcpy(&done, d_done, sizeof(bool), cudaMemcpyDeviceToHost);
	} while (!done);

	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	float elapsedTime;
	cudaEventElapsedTime(&elapsedTime, start, stop);
	printf("\nGPU Time: %f s", elapsedTime / 1000);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);


	cudaFree(d_done);
	cudaFree(d_VertexArray);
	cudaFree(d_adjLists);
	cudaFree(d_front);
	cudaFree(d_Visited);

}