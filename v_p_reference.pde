
/* 
 *  v_p_reference.pde
 *  Alternates high-low volumes to assist in 
 *  determining sound pressure level shifts
 *  
 *  Ian Callender
 *  ian@iancallender.net
 *  March 2017
 *  
 */
 
 // utilizes Ableton Live & LiveOSC/TouchOSC to set volume
import oscP5.*;
import netP5.*;

// Declarations
OscP5 oscP5;
NetAddress myRemoteLocation;
int oscP5port = 9001;
int myRemoteLocationPort = 7099;

boolean bool=true;
int vol1, vol2;
// if system, max = 70; if ableton, max=100
int volume_min = 1, volume_max = 100; 

void setup()
{
  // Window properties
  size(200, 200);
  frameRate(.2);

  // Setup OSC
  oscP5 = new OscP5(this, oscP5port);
  myRemoteLocation = new NetAddress("localhost", myRemoteLocationPort);

  // Each system volume click is ~2dB

  // With curve = 100...
  // 10dB, no matter the volume
  vol1 = 80;
  vol2 = 17;


  // Further Tests...
  
  // With curve = 100...
  // Same difference, same dB change?
  vol1 = 95;
  vol2 = 32;
  //  No!

  // With curve = 0...
  // 10dB, no matter the volume
  vol1 = 80;
  vol2 = 55;

  // Same difference, same dB change?
  vol1 = 90;
  vol2 = 65;
  // About, yes!

  // Same difference, same dB change?
  vol1 = 70;
  vol2 = 45;
  // About, yes!

  // Therefore, do not utilize Ableton curving
  
  // What's 6dB then?
  vol1 = 90;
  vol2 = 75;
  // yup, just about

  vol1 = 70;
  vol2 = 55;
  // same here
  
}

void draw()
{
  // note difference to see decibel change
  setVolumeOSC((bool)?vol1:vol2);
  bool = !bool;
}

void keyPressed() {
  if (key == CODED) {
    if (keyCode == LEFT) {
      vol1++;
      vol1 = constrain(vol1, vol2, volume_max);
    }
    if (keyCode == RIGHT) {
      vol1--;
      vol1 = constrain(vol1, vol2, volume_max);
    }
    if (keyCode == UP) {
      vol2++;
      vol2 = constrain(vol2, volume_min, vol1);
    }
    if (keyCode == DOWN) {
      vol2--;
      vol2 = constrain(vol2, volume_min, vol1);
    }
    println(vol1+" - "+vol2+" = "+(vol1-vol2));
  }
}

boolean setVolumeOSC (int vol) {
  OscMessage myMessage = new OscMessage("/live/master/volume");
  myMessage.add( float(vol) / 100);
  oscP5.send(myMessage, myRemoteLocation);
  return true;
}
