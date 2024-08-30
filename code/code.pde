import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

String audioFileName = "Chill 4.mp3";
//String audioFileName = "chill2.mp3";


float fps = 144;
float delta = 1/fps;
float smoothingFactor = 0.8;

AudioPlayer track;
FFT fft;
Minim minim;

// General
int bands = 512; // must be multiple of two
float rectSize = 7.5;
float spacing = 2;

float[] spectrum = new float[bands];
float[] sum = new float[bands];

// Graphics
float unit;
int groundLineY;
PVector center;

int stars = 400;
int starBuffer = 150;
float[] sX = new float[stars];
float[] sY = new float[stars];
float[] targetXs = new float[stars];
float[] targetYs = new float[stars];


int staticStars = 400;
float[] stX = new float[staticStars];
float[] stY = new float[staticStars];

void settings() {
  fullScreen();
  //size(w, h);
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

  for (int i = 0; i < stars; i++) {
    sX[i] = random(0, width);
    sY[i] = random(0, height);
    stX[i] = random(0, width);
    stY[i] = random(0, height);
    targetXs[i] = random(0, width);
    targetYs[i] = random(0, height);
  }

  track.cue(180000); // Cue in milliseconds
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
  fill(0);
  noStroke();
  rect(0, 0, width, height);
  noFill();
  drawStars(sum[0] > 10, sum[0]);
  drawCircles(sum, width/2, height/2);
  noStroke();
  drawWaveform(sum, width/2 - ((fftSize * rectSize)/2) - (spacing*fftSize), height/2);
}

void drawWaveform(float[] sum, float x, float y) {
  for (int i = 0; i < 24; i++) {
    float h =  map(sum[i] * 4, 0, 1000, 0, 300);
    //fill(random(0,255),random(0,255),random(0,255));
    fill(168+(i*10), 0+(i*10), 0+(i*4));
    rect((i*rectSize*2)+(i+2) + x, y-h, rectSize*2, h);
    rect((i*rectSize*2)+(i+2) + x, y, rectSize*2, h);
  }
}

void drawCircles(float[] sum, float x, float y) {
  for (int i = 0; i < 5; i++) {
    float r = map(sum[i] * 10, 0, 400, 400, 500);
    noFill();
    strokeWeight(i);
    stroke(150+(i*10), 0+(i*10), 0+(i*4));
    circle(x, y, r);
  }
}

void drawStars(boolean trigger, float increase) {
  //static
  for (int i = 0; i < staticStars; i++) {
    fill(255);
    float size =  1.5 + map(increase, 0, 100, 0, 3);
    rect(stX[i], stY[i], size, size);
  }
  //dynamic
  for (int i = 0; i < stars; i++) {
    float speed = random(1, 10) * delta;
    fill(255);
    sX[i] = stepTowards(sX[i], targetXs[i], speed);
    sY[i] = stepTowards(sY[i], targetYs[i], speed);
    float size =  2.5-speed + map(increase, 0, 100, 0, 3);
    rect(sX[i], sY[i], size, size);
  }
  if (trigger) {
    for (int i = 0; i < stars; i++) {
      float xMod = targetXs[i] + random(-50, 50);
      float yMod = targetYs[i] + random(-50, 50);
      while (xMod < -starBuffer || xMod > width+starBuffer) {
        xMod = targetXs[i]  + random(-50, 50);
      }
      while (yMod < -starBuffer || yMod > height+starBuffer) {
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
