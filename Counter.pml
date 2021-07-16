#define R 3
#define B 2

// variables used in the algorithm
byte c[B] = 0;
bit isEdited[R] = 0;
int reader_id = 0;  // not part of the algorithm

active proctype writer() {
  do
  :: true -> // just loop infinitely
      int index = B-1;
      int carry = 0;
      int i;

cc:   // continue carrying
      if 
      :: c[index] == 255 -> 
         i = 0;
         for (i : 0 .. R-1) {
            isEdited[i] = 1;
         }
         c[index] = 0;

         index--;
         carry = 1;
      :: else ->
         if
         :: carry == 1 -> 
            carry = 0;
         :: else -> skip;
         fi;

         i = 0;
         for (i : 0 .. R-1) {
           isEdited[i] = 1;
         }
         c[index]++;
      fi;

      printf("Incremented byte %d to %d\n", index, c[index])

      if 
         :: carry == 1 && index >= 0 -> 
            goto cc;          // move to next byte and repeat
         :: else -> skip;
      fi;
  od
}

active [R] proctype reader() {
   byte local_copy[B] = 0;
   byte local_copy_decoy[B] = 0; 
   int my_id;

   // for verification only
   byte helper1[B] = 0;  // value of c at the beginning of the read
   byte helper2[B] = 0;  // value of c at the end of the read

   // give each reader unique id corresponding to bit in isEdited
   d_step {
      my_id = reader_id;
      reader_id++;
   }

   do
   :: true ->
      do
      :: isEdited[my_id] == 1 ->   // repeat until a complete value of counter is obtained
sr:      isEdited[my_id] = 0;      // sr: short for "start read"
         int i;
         atomic {                  // make sure the c=v here for verification
            i = 0;
            for(i : 0 .. B-1) {
               helper1[i] = c[i];
            }
         }
         i = 0;
         for(i : 0 .. B-1) {
            local_copy_decoy[i] = c[i];
         }
         atomic {                  // or the c=v here for verification
            i = 0;
            for(i : 0 .. B-1) {
               helper2[i] = c[i];
            }
         }

         if 
         :: isEdited[my_id] == 0 ->    // if no writing occured during the above 10 lines, continue
            i = 0;
            for(i : 0 .. B-1) {
               local_copy[i] = local_copy_decoy[i];
            }
rc:         printf("Reader %d: read completed\n", my_id); // rc: short for "read complete"
            goto fin;
         :: else ->
            printf("Number %d decoy was attacked!!\n", my_id);
         fi;
      :: else -> skip;
      od 
     
   // check helpers are the same as local_copy
fin:  atomic {
         i = 0;
         for (i : 0 .. B-1) { 
            assert(local_copy[i] == helper1[i] || local_copy[i] == helper2[i]);
         }
      }     
   :: else -> break;
   od
}

// require that, under weak fairness, reads complete eventually even if writes subside.
ltl complete_read { []((reader[1]@sr) implies eventually (reader[1]@rc))}
