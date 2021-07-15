import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

public class Counter
{
    // global variables 
    static int NUM_READERS;
    static int NUM_BYTES;
    static int NUM_ROUNDS;
    
    static Byte[] c;
    static Boolean[] isEdited;
    static Byte Global_version = 0;

    public static void main(String[] args) {
        
        try {
            NUM_READERS = Integer.parseInt(args[0]);
            NUM_BYTES   = Integer.parseInt(args[1]);
            NUM_ROUNDS  = Integer.parseInt(args[2]);
        } catch (Exception e) {
            System.out.println("Usage: java RWApp [NUM_READERS] [NUM_BYTES] [NUM_ROUNDS]");
            System.exit(255);
        }
        
        System.out.println(""+Runtime.getRuntime().availableProcessors());
                   
        c = new Byte[NUM_BYTES];
        isEdited = new Boolean[NUM_READERS];

        for (int i = 0; i < NUM_BYTES; i++){
            c[i] = 0x0;
        }

        for (int i = 0; i < NUM_READERS; i++){
            isEdited[i] = false;
        }

        // Start the threads 
        Writer w = new Writer(NUM_ROUNDS);
        
        for (int i = 0; i < NUM_READERS; i++) {
            Reader r = new Reader(i, NUM_ROUNDS);
            r.start();
        }

        w.start();
    }
    
    public static class Reader extends Thread {
        // member vars
        private int id;
        private int rounds;
        private Byte[] local_c;
        private Byte[] local_c_decoy;  // inspired by latest rick and morty season 5 episode 2 "decoy family"
        private int version;
        
        public Reader(int id, int rounds){
            this.id = id;
            this.rounds = rounds;
            this.local_c = new Byte[NUM_BYTES];
            this.local_c_decoy = new Byte[NUM_BYTES];
            this.version = 0;

            for (int i = 0; i < NUM_BYTES; i++){
                this.local_c[i] = 0x0;
                this.local_c_decoy[i] = 0x0;
            }
        }
        
        @Override
        public void run() {
            int r = 0;
            while(r < this.rounds || (NUM_ROUNDS == 0)){ 
                while(isEdited[this.id] == true) { // repeat until a complete value of counter is obtained
                    isEdited[this.id] = false; // writer interleave possible between this line and 1 above? 
                    for (int i = 0; i < NUM_BYTES; i++){ 
                        this.local_c_decoy[i] = c[i];
                    }
                    if(isEdited[this.id] == false){   // no writing occured during the above 3 lines
                        for (int i = 0; i < NUM_BYTES; i++){
                            this.local_c[i] = this.local_c_decoy[i];
                        }   

                        System.out.println("Reader " + this.id + ": updated");
                    }
                    else { // someone attacked our decoy 
                        System.out.println("#" + this.id + " decoy attacked!!!");
                    }

                    //System.out.println("Reader " + this.id + ": " + Arrays.toString(this.local_c));
                    //System.out.println("Reader " + this.id + ": " + byteToLong(this.local_c, NUM_BYTES));
                }

                // 
                System.out.println("Reader " + this.id + ": " + byteToLong(this.local_c, NUM_BYTES));
                // else {
                //     System.out.println("Reader " + this.id + ": " + byteToLong(this.local_c, NUM_BYTES));
                // }

                try { Thread.sleep(ThreadLocalRandom.current().nextInt(10, 100)); } catch(InterruptedException e) {}
                r++;
            }
        }
    }
    
    public static class Writer extends Thread{
        // member vars
        private int rounds;
        
        public Writer(int rounds){
            this.rounds = rounds;
        }
        
        @Override
        public void run() {
            int r = 0;
            while(r < this.rounds || (NUM_ROUNDS == 0)){       
                // c[c.length-1]++; // just for testing
                // widening primitive promote to int for byte
                // bitArray[i] = (byte) (bitArray[i] | bitMask[j]);
                // Byte.byteValue();
                
                int index = c.length-1;
                boolean carry = false;

                do{ 
                    // if(carry){
                    //     index--;
                    //     System.out.println("index: " + index + ", c[index] = " + c[index] + ", c[index+1] = " + c[index+1]); 
                    //     carry = false;
                    // }

                    if((c[index].byteValue() & 0xff) == 0xff){ // ignore 2's complement
                        c[index] = 0x0;
                        index--;
                        carry = true; 
                    }
                    else{
                        if(carry){
                            System.out.println("carried 1");
                            carry = false;
                        }
                        c[index]++;
                        System.out.println("Incremented to " + byteToLong(c, NUM_BYTES)); 
                    }
                } while (carry && (index >= 0));

                // notify
                for(int i = 0; i < NUM_READERS; i++){
                    isEdited[i] = true;
                }

                r++;

                // resort to this for now
                try { Thread.sleep(ThreadLocalRandom.current().nextInt(10, 100)); } catch(InterruptedException e) {}
            }
        }
    }

    public static long byteToLong(Byte[] bytes, int length) {
        long val = 0;
        if(length>8) throw new RuntimeException("64 bit overflow");
        for (int i = 0; i < length; i++) {
            val=val<<8;
            val=val|(bytes[i] & 0xff);
        }
        return val;
    }
}
