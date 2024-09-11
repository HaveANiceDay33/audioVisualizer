import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

float fps = 60;
float delta = 1/fps;
float smoothingFactor = 0.8;

AudioPlayer track;
FFT fft;
Minim minim;

///////// VISUALIZATION PARAMETERS ////////////
// make a "data" folder next to this code file and add tracks to that
String audioFileName = "Chill3.mp3";
int trackStartTimeMs = 318000;

//stars
int movingStars = 400;
int starTargetPositionRange = 150;
int staticStars = 400;
float baseStarSize = 2;
float starSensitivity = 3;

// circles
float circleSensitivity = 40;
int baseThickness = 1;
int numCircles = 4;

// bars
boolean drawNorthBars = true;
boolean drawSouthBars = true;
boolean drawRoundedBars = true;
float southRadius = 10;
float northRadius = 10;
float barSensitivity = 8;

// rgb for these
float[] backgroundColor = {1, 33, 43};
float[] barBaseColor = {72, 242, 5};
float[] circleBaseColor = {21, 183, 232};
float[] staticStarColor = {250, 250, 250};
float[] movingStarColor = {12, 237, 132};

// draw things or not
boolean drawBars = true;
boolean drawCircles = true;
boolean drawStars = true;

////////// ADVANCED PARAMETERS /////////////
int bands = 512; // must be multiple of two
float rectSize = 7.5;
float spacing = 2;

float[] spectrum = new float[bands];
float[] sum = new float[bands];

// Graphics
float unit;
int groundLineY;
PVector center;

float[] sX = new float[movingStars];
float[] sY = new float[movingStars];
float[] targetXs = new float[movingStars];
float[] targetYs = new float[movingStars];

float[] stX = new float[staticStars];
float[] stY = new float[staticStars];

void settings() {
  fullScreen();
  smooth(8);
}

void setup() {
  frameRate(fps);

  // Graphics related variable setting
  unit = height / 100; // Everything else can be based around unit to make it change depending on size
  strokeWeight(unit / 10.24);
  groundLineY = height * 3/4;
  center = new PVector(width / 2, height * 3/4);

  minim = new Minim(this);
  track = minim.loadFile(audioFileName, 2048);
 
  track.loop();

  fft = new FFT( track.bufferSize(), track.sampleRate() );
  fft.logAverages(22, 3);

  for (int i = 0; i < movingStars; i++) {
    sX[i] = random(0, width);
    sY[i] = random(0, height);
    stX[i] = random(0, width);
    stY[i] = random(0, height);
    targetXs[i] = random(0, width);
    targetYs[i] = random(0, height);
  }

  track.cue(trackStartTimeMs); // Cue in milliseconds
}

void draw() {
  fft.forward(track.mix);
  int fftSize = fft.avgSize();
  spectrum = new float[fftSize];
  for (int i = 0; i < fftSize; i++)
  {
    spectrum[i] = fft.getAvg(i) / 2;
    // Smooth the FFT spectrum data by smoothing factor
    sum[i] += (abs(spectrum[i]) - sum[i]) * smoothingFactor;
  }
  // Reset canvas
  fill(backgroundColor[0], backgroundColor[1], backgroundColor[2]);
  noStroke();
  rect(0, 0, width, height);
  noFill();

  if (drawStars) {
    drawStars(sum[0] * starSensitivity > 10, sum[0] * starSensitivity);
  }
  if (drawCircles) {
    drawCircles(sum, width/2, height/2);
  }
  if (drawBars) {
    noStroke();
    drawWaveform(sum, width/2 - ((fftSize * rectSize)/2) - (spacing*fftSize), height/2);
  }  
}

void drawWaveform(float[] sum, float x, float y) {
  for (int i = 0; i < 24; i++) {
    float h =  map(sum[i] * barSensitivity, 0, 1000, 0, 300);
    fill(barBaseColor[0]+(i*10), barBaseColor[1]+(i*10), barBaseColor[2]+(i*4));
    if (drawNorthBars) {
      if (drawRoundedBars) {
        rect((i*rectSize*2)+(i+2) + x, y-h, rectSize*2, h, northRadius, northRadius, drawSouthBars ? 0: southRadius, drawSouthBars ? 0: southRadius);
      } else {
        rect((i*rectSize*2)+(i+2) + x, y-h, rectSize*2, h);
      }
    }
    if (drawSouthBars) {
      if (drawRoundedBars) {
        rect((i*rectSize*2)+(i+2) + x, y, rectSize*2, h, drawNorthBars ? 0 : northRadius, drawNorthBars ? 0 : northRadius, southRadius, southRadius);
      } else {
        rect((i*rectSize*2)+(i+2) + x, y, rectSize*2, h);
      }
    }
  }
}

void drawCircles(float[] sum, float x, float y) {
  for (int i = baseThickness; i < (numCircles + baseThickness); i++) {
    float r = map(sum[i] * circleSensitivity, 0, 400, 400, 500);
    noFill();
    strokeWeight(i);
    stroke(circleBaseColor[0]+(i*10), circleBaseColor[1]+(i*10), circleBaseColor[2]+(i*4));
    circle(x, y, r);
  }
}

void drawStars(boolean trigger, float increase) {
  //static
  for (int i = 0; i < staticStars; i++) {
    fill(staticStarColor[0], staticStarColor[1], staticStarColor[2]);
    float size =  1.5 + map(increase, 0, 100, 0, 3);
    rect(stX[i], stY[i], size, size);
  }
  //dynamic
  for (int i = 0; i < movingStars; i++) {
    float speed = random(1, 10) * delta;
    fill(movingStarColor[0], movingStarColor[1], movingStarColor[2]);
    sX[i] = stepTowards(sX[i], targetXs[i], speed);
    sY[i] = stepTowards(sY[i], targetYs[i], speed);
    float size =  2.5-speed + map(increase, 0, 100, 0, 3);
    rect(sX[i], sY[i], size, size);
  }
  if (trigger) {
    for (int i = 0; i < movingStars; i++) {
      float xMod = targetXs[i] + random(-50, 50);
      float yMod = targetYs[i] + random(-50, 50);
      while (xMod < -starTargetPositionRange || xMod > width+starTargetPositionRange) {
        xMod = targetXs[i]  + random(-50, 50);
      }
      while (yMod < -starTargetPositionRange || yMod > height+starTargetPositionRange) {
        yMod = targetYs[i]  + random(-50, 50);
      }
    }
  }
}

float stepTowards(float cur, float target, float step) {
  if (target > cur) {
    if (target < cur + step) {
      return target;
    }
    return cur + step;
  }
  if (target < cur) {
    if (target > cur - step) {
      return target;
    }
    return cur - step;
  }
  return cur;
}
