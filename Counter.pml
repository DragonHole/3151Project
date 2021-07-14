#define MutexDontCare
#include "critical2.h"

#define R 3
#define B 2

// for verification only
int helper = 0;
bit changed[R] = 0;

// variables used in the algorithm
int c = 0;
bit note[R] = 0;

int reader_id = 0;  // not part of the algorithm

active proctype writer() {
  printf("i am writer %d\n", _pid);
  do
  :: true -> // just loop infinitely
     c++;
     printf("Incremented: %d\n", c);
     
     int i = 0;
     do
     :: i < R -> 
        note[i] = 1;
        i++;
     :: else -> break;
     od 
  od
}

active [R] proctype reader() {
  int local_copy = 0;
  int local_copy_decoy = 0;  
  int my_id;

  d_step {
      my_id = reader_id;
      reader_id++;
  }

  printf("i am reader %d\n", _pid);
  do
  :: true ->
     do
     :: note[my_id] == 1 ->   // make sure the v here  
        atomic {
           note[my_id] = 0;
           helper = c;
        }
        local_copy_decoy = c;

        if 
        :: note[my_id] == 0 ->
           local_copy = local_copy_decoy;
           printf("Reader %d updated\n", my_id);
        :: else ->
           printf("Number %d decoy is attacked!!\n", my_id);
        fi 
     //   printf("Reader %d: %d\n", my_id, local_copy);
     //:: else ->
     //   printf("Reader %d: %d\n", my_id, local_copy);
     :: else -> break;
     od 
     // is the same as local_copy here
     assert (local_copy == helper);
cp:  printf("Reader %d: %d\n", my_id, local_copy);
  :: else -> break;
  od
}

// // /* 
// // LTL formulae

// a value v read by a reader is correct if the counter assumes v while being read by reader.
// 1. prove a change in value will be followed by a read of the changed value. 
// 2. prove 
// /*

// ltl change { []() }

// #define MutexDontCare
// #include "critical2.h"

// #define R 3
// #define B 2

// byte c[B] = 0;
// bit note[R] = 0;

// int reader_id = 0;  // not part of the algorithm

// active proctype writer() {
//   printf("i am writer %d\n", _pid);
//   int index = B-1;
//   int carry = 0;
//   do
//   :: true -> // just loop infinitely
//       if // does this work like an else if statement?
//       :: c[index] == 255 -> 
//           index--;
//           c[index] = 0;
//           carry = 1;
//       :: else ->
//           if
//           :: carry == 1 -> 
//               printf("carried 1");
//               carry = 0;
//           :: else -> skip;
//           fi;
//           c[index]++;
//           printf("Incremented: %d\n", c[index])
//       fi;
     
//      int i = 0;
//      do
//      :: carry == 1 && i < R -> 
//         note[i] = 1;
//         i++;
//      :: else -> break;
//      od 
//   od
// }

// active [R] proctype reader() {
//   byte local_copy[B] = 0;
//   byte local_copy_decoy[B] = 0;  
//   int my_id;

//   d_step {
//       my_id = reader_id;
//       reader_id++;
//   }

//   printf("i am reader %d\n", _pid);
//   do
//   :: true ->
//      if
//      :: note[my_id] == 1 ->
//         note[my_id] = 0;
//         int i = 0;
//         for(i : 0 .. B) {
//             local_copy_decoy[i] = c[i];
//         }
//         if 
//         :: note[my_id] == 0 ->
//             for(i : 0 .. B) {
//                local_copy[i] = local_copy_decoy[i];
//             }
//             printf("Reader %d updated\n", my_id);
//         :: else ->
//             printf("Number %d decoy is attacked!!\n", my_id);
//         fi 

//         printf("Reader %d: %d\n", my_id, local_copy);
//      :: else ->
//         printf("Reader %d: %d\n", my_id, local_copy);
//      fi 
//   :: else -> break;
//   od
// }
