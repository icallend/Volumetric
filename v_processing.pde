
/* 
 *  v_processing.pde
 *  Reads serial values from arduino+IR sensor,
 *  applies dynamic normalization algorithm and any difference variation algo,
 *  and sends new volume over OSC
 *  
 *  Ian Callender
 *  ian@iancallender.net
 *  March 2017
 *  
 */

// DYNAMIC NORMALIZATION
// MEDIAN FILTER

// utilizes Ableton Live & LiveOSC/TouchOSC to set master volume
import processing.serial.*;
import oscP5.*;
import netP5.*;

// Declarations
OscP5 oscP5;
NetAddress myRemoteLocation;
int oscP5port = 9001;
int myRemoteLocationPort = 7099;

Serial port;

int lf = 10;  // ASCII linefeed 

String inSerialData;
float inSerialDatafloat;
float oldSerialDatafloat;

int sample_size = 3;
float[] oldSerialDatafloatArr = new float[sample_size];

int inSerialData_min = 69, inSerialData_max = 466;
float volume_min = 0.0, volume_max = 1.0; // if system, max = 70; if ableton, max=100 (but really 1)

float scaleFactor = .026;

float C = .45;


void setup()
{
  // Window properties
  size(200, 200);
  frameRate(50);

  // Setup OSC
  oscP5 = new OscP5(this, oscP5port);
  myRemoteLocation = new NetAddress("localhost", myRemoteLocationPort);

  // Setup Arduino In
  String portName = Serial.list()[3]; // <-- this is not certain
  port = new Serial(this, portName, 9600);

  // Throw out the first reading, in case we started reading 
  // in the middle of a string from the sender.
  inSerialData = port.readStringUntil(lf);
  port.clear();
  port.bufferUntil(lf);
  inSerialData = null;
}


void draw()
{
}


boolean setVolumeOSC (float vol) {
  OscMessage myMessage = new OscMessage("/live/master/volume");
  myMessage.add( vol );
  oscP5.send(myMessage, myRemoteLocation);
  return true;
}

// Calculates the base-b logarithm of a number x
float logbx (float x, float base) {
  return (log(x) / log(base));
}


// in: distance, in m
// out: not the decibel shift but the volume shift, in volume's scale
float dn (float dist) {

  float db_normalizer = (6*logbx(dist, 2));  
  float volumeShift = (scaleFactor*db_normalizer);
  println("dn-db \t"+db_normalizer);
  println("dn-vol \t"+volumeShift);

  return volumeShift;
}

// in: distance, in m
// out: an arbitrary shift, in volume's scale
float f (float dist, float vol_prealloc) {

  float f_ret = 0;
  float low = inSerialData_min/100;
  float high = inSerialData_max/100;

  //*
  // DIMINISHING
  f_ret = dist;
  low = inSerialData_min/100;
  high = inSerialData_max/100;
  /*/
   // AUGMENTING
   f_ret = (100.0/dist);
   low = 100.0/(inSerialData_max/100.0);
   high = 100.0/(inSerialData_min/100.0);
   //*/

  /*
  // INCONSISTENT
   float scaled = map(dist, inSerialData_min/100, inSerialData_max/100, 0, 10);
   if (scaled < 5) {
   f_ret = 20/scaled;
   } else if (scaled >= 8) {
   f_ret = 14;
   } else {
   f_ret = (-5*(scaled*scaled)) + (60*scaled) - 160 ;
   }
   low = 0;
   high = 20;
   //*/
  println("f_ret \t"+f_ret +"\t (low: "+low+", high: "+high+")");

  /*
  f_ret = map(f_ret, low, high, volume_min, volume_max);
   println("f_ret map \t"+f_ret +"\t (low: "+volume_min+", high: "+volume_max+")");
  /*/
  f_ret = map(f_ret, low, high, volume_min, volume_max-vol_prealloc);
  println("f_ret map \t"+f_ret +"\t (low: "+volume_min+", high: "+volume_max+", effective high: "+(volume_max-vol_prealloc)+")");
  //*/

  return f_ret;
}


void serialEvent(Serial p) { 

  inSerialData = p.readStringUntil(lf);
  //println("ISD:"+inSerialData);

  // could switch this to a try/catch
  if ( (inSerialData != null) ) {
    inSerialData = trim(inSerialData);
    if ( !inSerialData.equals("") ) {

      // constrain the converted float to known min and max. Don't want a negative distance or 'to make it hit 11' (map doesn't constrain)
      inSerialDatafloat = constrain(Float.parseFloat( inSerialData ), inSerialData_min, inSerialData_max);

      float inSerialDatafloat_adj = inSerialDatafloat/100; // division for cm->m
      //*
      // DYNAMIC NORMALIZATION
      inSerialDatafloat = dn(inSerialDatafloat_adj)+C;
      println("+C \t"+inSerialDatafloat);
      /*/
       // DIFFERENCE VARIATION
       float dn_temp = dn(inSerialDatafloat_adj);
       inSerialDatafloat = dn_temp+f(inSerialDatafloat_adj, dn_temp);
       //*/
      inSerialDatafloat = constrain(inSerialDatafloat, volume_min, volume_max);
      println("Constr \t"+inSerialDatafloat);
      println("");


      /* MEDIAN FILTER */

      // shift everything left
      for (int i=0; i<sample_size-1; i++) {
        oldSerialDatafloatArr[i] = oldSerialDatafloatArr[i+1];
      }
      oldSerialDatafloatArr[sample_size-1] = inSerialDatafloat;

      // by incorporating min & max into sum loop, O(3n)-->O(n)
      float sample_sum = 0;
      float sample_min = volume_max, sample_max = volume_min;

      for (int i=0; i<sample_size; i++) {
        float current = oldSerialDatafloatArr[i];
        sample_sum += current;
        if (current > sample_max) sample_max = current;
        if (current < sample_min) sample_min = current;
      }
      //float medianFilter = (sample_sum - sample_max - sample_min)/(sample_size-2);
      inSerialDatafloat = (sample_sum - sample_max - sample_min)/(sample_size-2);

      /* END MEDIAN FILTER */


      // if there's been a change in volume
      if ( inSerialDatafloat != oldSerialDatafloat ) {
        println("SE -> SET "+inSerialDatafloat+"\n");
        setVolumeOSC(inSerialDatafloat);
        // if volume set executes properly, reset / get ready to do it all again
        oldSerialDatafloat = inSerialDatafloat;
        inSerialData = null;
      }
    }
    inSerialData = null;
  }
}
