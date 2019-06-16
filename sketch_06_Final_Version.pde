///////////////MINDANDMATTER////////////////// //<>//
//NENE BRODE//////////////////////////////////
//MASTERS OF ART IN COMMUNICATIONS & CULTURE//
//CREDIT TO CONTRIBUTORS: 
//KIERAN FROM THE DME
//ANDREAS SCHLEGEL FOR HIS CODE EXAMPLES
//DANIELS SHIFFMAN FOR HIS MANY TUTORIALS
/////////////////////////////////////////////

//PRETEXT////////////////////////////////////
/////////////////////////////////////////////

//Particle system
ArrayList<ParticleSystem> systems;

//Geolocation data
String reportString;
String myString;
String latitude, longitude;
Table table;

//Variables for cell array
float minLat, maxLat, minLong, maxLong, ht;
Table finalProx = new Table();

import java.nio.*;
import org.openkinect.processing.Kinect2;

//Kinect 
Kinect2 kinect2;

float angle = 3.141594;
float scaleValue = 50;

//Change color of the point cloud
int drawState = 1;

//openGL
PGL pgl;
PShader sh;

//VBO buffer location in the GPU
int vertexVboId;
int colorVboId;

int vertLoc;
int colorLoc;

//Dial
PFont small, big;
int radius = 100;

//import data from Neurosky via TCP
import processing.net.*;
JSONObject json;

//Import sound library
import processing.sound.*;

//Variables for Neurosky
Client myClient;
int meditation;
int attention;
int poorSignalLevel;
int delta;
int theta;
int lowAlpha;
int highAlpha;
int lowBeta;
int highBeta;
int lowGamma;
int highGamma;

//White noise and white screen
WhiteNoise noise;
float amp=0.0;
float a;
float b;

////////////////////////////////////////////
//SET UP??????//////////////////////////////
////////////////////////////////////////////

void setup() {
  size(1440, 900, P3D);

  //Dial
  small = createFont("sansSerif", 10);
  big = createFont("sansSerif", 30);
  fill(0);
  textAlign(CENTER, CENTER);

  //Neurosky TCP
  myClient = new Client(this, "127.0.0.1", 13854);
  myClient.write("{\"appName\": \"helloWorld\", \"appKey\": \"0123456789012345678901234567890123456789\", \"enableRawOutput\": false, \"format\":\"Json\"}");

  // Create a noise generator and filters
  noise = new WhiteNoise(this);
  //smooth();
  frameRate(25);
  noStroke();

  //run external program to get cell location from combain api and wait for it to finish
  Process p = exec("/Users/nenebrode/Desktop/python/runpython.txt");

  try {

    int result = p.waitFor();
    println("the process returned"+result);
  } 
  catch (InterruptedException e) {
  }

  String[] tempLoc = loadStrings("/Users/nenebrode/Desktop/python/location");
  tempLoc = split(tempLoc[0], ",");
  latitude = tempLoc[0];
  longitude = tempLoc[1];

  print(latitude, longitude, "\n");

  // import cell tower, antenna, and wifi information

  Table table = new Table();
  table = loadTable("Site_Data_GTA.csv", "header");
  table.setColumnType(1, "float");
  table.sort (1);

  // compare latitude
  Table proxTable = new Table();
  proxTable.setColumnTitles(table.getColumnTitles());
  for (TableRow row : table.rows ()) {
    if ((row.getFloat(1)>float(latitude)-0.2) && (row.getFloat(1)<float(latitude)+0.2)) {
      proxTable.addRow(row);
    }
  }
  println("done latitude");
  proxTable.setColumnType(2, "float");

  finalProx.setColumnTitles(table.getColumnTitles());
  finalProx.setColumnType(3, "float");

  // compare longitude
  for (TableRow row : proxTable.rows ()) {
    if ((row.getFloat(2)>float(longitude)-0.23) && (row.getFloat(2)<float(longitude)+0.23)) {
      println("added");
      finalProx.addRow(row);
    }
  }
  print("done longitude");
  saveTable(finalProx, "finalProx.csv");

  finalProx.sort (1); 
  minLat = finalProx.getFloat(0, 1);
  maxLat = finalProx.getFloat(finalProx.getRowCount()-1, 1);
  finalProx.sort (2); 
  maxLong = finalProx.getFloat(0, 2);
  minLong = finalProx.getFloat(finalProx.getRowCount()-1, 2);

  systems = new ArrayList<ParticleSystem>();
  for (TableRow row : finalProx.rows()) {
    float x = map(row.getFloat(2), minLong, maxLong, 0, width);
    float y = map(row.getFloat(1), minLat, maxLat, 0, height);
    float ht = map(row.getFloat(4), 0, .1, -2, 2);
    systems.add(new ParticleSystem(1, new PVector(x, y)));
    println("ht");
  }

  //Kinect
  kinect2 = new Kinect2(this);
  // Start all data
  kinect2.initDepth();
  kinect2.initIR();
  kinect2.initVideo();
  kinect2.initRegistered();
  kinect2.initDevice();

  //start shader
  //shader usefull to add post-render effects to the point cloud
  sh = loadShader("frag.glsl", "vert.glsl");
  //smooth(16);

  //create VBO
  PGL pgl = beginPGL();

  // allocate buffer big enough to get all VBO ids back
  IntBuffer intBuffer = IntBuffer.allocate(2);
  pgl.genBuffers(2, intBuffer);

  //memory location of the VBO
  vertexVboId = intBuffer.get(0);
  colorVboId = intBuffer.get(1);

  endPGL();
}

////////////////////////////////////////////
//DRAWING//////////////////////////////////
////////////////////////////////////////////

void draw() {

  background(0);

  //IR image
  pushMatrix();
  translate(width/2, height/2, scaleValue);
  rotateY(angle);
  stroke(255);

  //obtain the XYZ camera positions based on the depth data
  FloatBuffer depthPositions = kinect2.getDepthBufferPositions();

  //obtain the color information as IntBuffers
  IntBuffer irData         = kinect2.getIrColorBuffer();
  IntBuffer registeredData = kinect2.getRegisteredColorBuffer();
  IntBuffer depthData      = kinect2.getDepthColorBuffer();

  pgl = beginPGL();
  sh.bind();

  //send the the vertex positions (point cloud) and color down the render pipeline
  //positions are render in the vertex shader, and color in the fragment shader
  vertLoc = pgl.getAttribLocation(sh.glProgram, "vertex");
  pgl.enableVertexAttribArray(vertLoc);

  //enable drawing to the vertex and color buffer
  colorLoc = pgl.getAttribLocation(sh.glProgram, "color");
  pgl.enableVertexAttribArray(colorLoc);

  int vertData = kinect2.depthWidth * kinect2.depthHeight;

  //vertex
  {
    pgl.bindBuffer(PGL.ARRAY_BUFFER, vertexVboId);
    // fill VBO with data
    pgl.bufferData(PGL.ARRAY_BUFFER, Float.BYTES * vertData * 3, depthPositions, PGL.DYNAMIC_DRAW);
    // associate currently bound VBO with shader attribute
    pgl.vertexAttribPointer(vertLoc, 3, PGL.FLOAT, false, Float.BYTES * 3, 0);
  }

  //color
  //change color of the point cloud depending on the depth, ir and color+depth information.
  switch(drawState) {
  case 0:
    pgl.bindBuffer(PGL.ARRAY_BUFFER, colorVboId);
    // fill VBO with data
    pgl.bufferData(PGL.ARRAY_BUFFER, Integer.BYTES * vertData, depthData, PGL.DYNAMIC_DRAW);
    // associate currently bound VBO with shader attribute
    pgl.vertexAttribPointer(colorLoc, 4, PGL.UNSIGNED_BYTE, false, Byte.BYTES, 0);
    break;
  case 1:
    pgl.bindBuffer(PGL.ARRAY_BUFFER, colorVboId);
    // fill VBO with data
    pgl.bufferData(PGL.ARRAY_BUFFER, Integer.BYTES * vertData, irData, PGL.DYNAMIC_DRAW);
    // associate currently bound VBO with shader attribute
    pgl.vertexAttribPointer(colorLoc, 4, PGL.UNSIGNED_BYTE, false, Byte.BYTES, 0);
    break;
  case 2:
    pgl.bindBuffer(PGL.ARRAY_BUFFER, colorVboId);
    // fill VBO with data
    pgl.bufferData(PGL.ARRAY_BUFFER, Integer.BYTES * vertData, registeredData, PGL.DYNAMIC_DRAW);
    // associate currently bound VBO with shader attribute
    pgl.vertexAttribPointer(colorLoc, 4, PGL.UNSIGNED_BYTE, false, Byte.BYTES, 0);//Byte.SIZE, 0);
    break;
  }

  // unbind VBOs
  pgl.bindBuffer(PGL.ARRAY_BUFFER, 0);

  //draw the point cloud as a set of points
  pgl.drawArrays(PGL.POINTS, 0, vertData);

  //disable drawing
  pgl.disableVertexAttribArray(vertexVboId);
  pgl.disableVertexAttribArray(colorVboId);

  sh.unbind();
  endPGL();
  popMatrix();

  //Neurosky
  pushMatrix();
  JSONObject packet;
  if (myClient.available() > 0 && myClient.active()) {
    String test = myClient.readString();
    packet = parseJSONObject(test);
    if (!packet.isNull("eSense")) {
      if (!packet.getJSONObject("eSense").isNull("attention"))
        attention = packet.getJSONObject("eSense").getInt("attention");
      if (!packet.getJSONObject("eSense").isNull("meditation"));
      meditation = packet.getJSONObject("eSense").getInt("meditation");
    }
    if (!packet.isNull("poorSignalLevel")) {
      poorSignalLevel = packet.getInt("poorSignalLevel");
    }
    if (!packet.isNull("eegPower")) {
      if (!packet.getJSONObject("eegPower").isNull("delta"))
        delta = packet.getJSONObject("eegPower").getInt("delta");
      if (!packet.getJSONObject("eegPower").isNull("theta"));
      theta = packet.getJSONObject("eegPower").getInt("theta");
      if (!packet.getJSONObject("eegPower").isNull("lowAlpha"))
        lowAlpha = packet.getJSONObject("eegPower").getInt("lowAlpha");
      if (!packet.getJSONObject("eegPower").isNull("highAlpha"))
        highAlpha = packet.getJSONObject("eegPower").getInt("highAlpha");
      if (!packet.getJSONObject("eegPower").isNull("lowBeta"))
        lowBeta = packet.getJSONObject("eegPower").getInt("lowBeta");
      if (!packet.getJSONObject("eegPower").isNull("highBeta"))
        highBeta = packet.getJSONObject("eegPower").getInt("highBeta");
      if (!packet.getJSONObject("eegPower").isNull("lowGamma"))
        lowGamma = packet.getJSONObject("eegPower").getInt("lowGamma");
      if (!packet.getJSONObject("eegPower").isNull("highGamma"))
        highGamma = packet.getJSONObject("eegPower").getInt("highGamma");
    }
  }

  //Map white screen 
  a = map(meditation, 0, 100, 0, 255);

  //White screen
  fill(255, a);
  rect(0, 0, 1440, 900);

  //Map white noise
  b = map(attention, 0, 100, 0.0, 1.0);

  //Play noise
  noise.play();
  noise.amp(b);   
  popMatrix();

  //Draw Particles
  pushMatrix();
  for (ParticleSystem ps : systems) {
    ps.run();
    ps.addParticle();
  } 
  popMatrix();

  //Dial
  pushMatrix();
  fill(255);
  translate(200, 200);
  stroke(0);
  textFont(small);
  for (int i=0; i<360; i+=5) {
    if (i % 20 == 0) {
      stroke(255);
      strokeWeight(2);
      float radi = radians(i);
      line(sin(radi)*radius, cos(radi)*radius, sin(radi)*radius*1.4, cos(radi)*radius*1.4);
      text(i, sin(radi)*radius*1.55, cos(radi)*radius*1.55);
    } else {
      strokeWeight(1);
      float radi = radians(i);
      line(sin(radi)*radius, cos(radi)*radius, sin(radi)*radius*1.2, cos(radi)*radius*1.2);
    }
  }

  stroke(255, 0, 0);
  strokeWeight(3);
  float dial = radians(attention);
  line(sin(dial)*radius*0.5, cos(dial)*radius*0.5, sin(dial)*radius, cos(dial)*radius);
  textFont(big);
  textAlign(CENTER);
  text(a, 0, 0);
  popMatrix();

  //Print Values
  pushMatrix();
  textAlign(RIGHT);
  textSize(12);
  fill(255, 0, 0);
  text("Poor Signal Level: " + poorSignalLevel, 1400, 50);
  text("Attention: " + attention, 1400, 75);
  text("Meditation: " + meditation, 1400, 100);
  text("Delta: " + delta, 1400, 125);
  text("Theta: " + theta, 1400, 150);
  text("Low Alpha: " + lowAlpha, 1400, 175);
  text("High Alpha: " + highAlpha, 1400, 200);
  text("Low Beta: " + lowBeta, 1400, 225);
  text("High Beta: " + highBeta, 1400, 250);
  text("Low Gamma: " + lowGamma, 1400, 275);
  text("High Gamma: " + highGamma, 1400, 300);

  popMatrix();

  ///Get camera image
  pushMatrix();
  kinect2.getIrImage();
  image(kinect2.getVideoImage(), 1050, 500, kinect2.colorWidth*0.2, kinect2.colorHeight*0.2);
  popMatrix();
}

///////////////MINDANDMATTER///////////////
