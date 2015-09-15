// Sonification, image as sound
// Reimplementation of image -> raw -> wav -> audacity filters -> wav -> raw -> image process
// Tomasz Sulej, generateme.blog@gmail.com, http://generateme.tumblr.com
// Bob Verkouteren, bob.verkouteren@gmail.com, http://applesandchickens.com 
// Licence: http://unlicense.org/

// Usage:
//   * press SPACE to save
//   * c or click to randomize effect settings
//   * f to randomize filters
//   * r to randomize raw settings

// set up filename
String filename = "test";
String fileext = ".jpg";
String foldername = "./";

int max_display_size = 800; // viewing window size (regardless image size)

boolean do_blend = false; // blend image after process
int blend_mode = OVERLAY; // blend type

boolean make_equalize = true; // equalize and normalize histogram

// image reader config
int r_rawtype = INTERLEAVED; // planar: rrrrr...ggggg....bbbbb; interleaved: rgbrgbrgb...
int r_law = NONE; // NONE, A_LAW, U_LAW
int r_sign = UNSIGNED; // SIGNED or UNSIGNED
int r_bits = B8; // B8, B16 or B24, bits per sample
int r_endianess = LITTLE_ENDIAN; // BIG_ENDIAN or LITTLE_ENDIAN
int r_colorspace = RGB; // list below 

// image writer config
int w_rawtype = INTERLEAVED; // planar: rrrrr...ggggg....bbbbb; interleaved: rgbrgbrgb...
int w_law = NONE; // NONE, A_LAW, U_LAW
int w_sign = UNSIGNED; // SIGNED or UNSIGNED
int w_bits = B8; // B8, B16 or B24, bits per sample
int w_endianess = LITTLE_ENDIAN; // BIG_ENDIAN or LITTLE_ENDIAN
int w_colorspace = RGB; // list below

// put list of the filters { name, sample rate }
float[][] filters = {
//  { DJEQ, 14100.0 },
//  { CANYONDELAY, 44100.0 },
//  { PHASER, 14100.0 },
//  { TAPSIGMOID, 44100.0 },
//  { ECHO, 31000.0 },
//  { VYNIL, 43100.0},
//  { BASSTREBLE, 44100.0 },
//  { ECHO, 44100.0 },
//  { COMB, 24410.0 }, 
//  { SHIFTR, 44100.0 },
//  { WAHWAH,44100.0 },
  { RANDMIX, 114100.0 }, 
  { FOURBYFOURPOLE, 44100.0 },
  { AUTOPHASER, 44100.0 },
//  { TREVERB, 44100.0 },
};

// EFFECTS!
final static int NOFILTER = -1;
final static int DJEQ = 0;
final static int COMB = 1;
final static int VYNIL = 2;
final static int CANYONDELAY = 3; 
final static int VCF303 = 4;
final static int ECHO = 5; 
final static int PHASER = 6;
final static int WAHWAH = 7;
final static int BASSTREBLE = 8; 
final static int SHIFTR = 9;
final static int TAPSIGMOID = 10;
final static int TAPAUTOPAN = 11;
final static int RANDMIX = 12;
final static int DIVIDER = 13;
final static int LFOPHASER = 14;
final static int FOURBYFOURPOLE = 15;
final static int AUTOPHASER = 16;
final static int AUAMPLIFY = 17;
final static int TREVERB = 18;

// colorspaces, NONE: RGB
final static int OHTA = 1001;
final static int CMY = 1002;
final static int XYZ = 1003;
final static int YXY = 1004;
final static int HCL = 1005;
final static int LUV = 1006;
final static int LAB = 1007;

// configuration constants
final static int A_LAW = 0;
final static int U_LAW = 1;
final static int NONE = 2;

final static int UNSIGNED = 0;
final static int SIGNED = 1;

final static int B8 = 8;
final static int B16 = 16;
final static int B24 = 24;

final static int LITTLE_ENDIAN = 0;
final static int BIG_ENDIAN = 1;

final static int PLANAR = 0;
final static int INTERLEAVED = 1;

// working buffer
PGraphics buffer;

// image
PImage img;

String sessionid;

AFilter afilter; // filter handler
RawReader isr; // image reader
RawWriter isw; // image writer
ArrayList<AFilter> filterchain = new ArrayList<AFilter>();

void setup() {
  sessionid = hex((int)random(0xffff),4);
  img = loadImage(foldername+filename+fileext);
  
  buffer = createGraphics(img.width, img.height);
  buffer.beginDraw();
  buffer.noStroke();
  buffer.smooth(8);
  buffer.background(0);
  buffer.image(img,0,0);
  buffer.endDraw();
  
  // calculate window size
  float ratio = (float)img.width/(float)img.height;
  int neww, newh;
  if(ratio < 1.0) {
    neww = (int)(max_display_size * ratio);
    newh = max_display_size;
  } else {
    neww = max_display_size;
    newh = (int)(max_display_size / ratio);
  }

  size(neww,newh);
  init_helper();

  isr = new RawReader(img.get(), r_rawtype, r_law, r_sign, r_bits, r_endianess);
  isr.r.convertColorspace(r_colorspace);
  isw = new RawWriter(img.get(), w_rawtype, w_law, w_sign, w_bits, w_endianess);

  prepareFilters(filters);
  
//  color tt = color(22,122,222);
//  color _luv = toLUV(tt);
//  println( getR(_luv) + "," + getG(_luv) + "," + getB(_luv));
//  _luv = fromLUV(_luv);
//  println( getR(_luv) + "," + getG(_luv) + "," + getB(_luv));
  
//  float in = -1;
//  float out = in;
//  float _prev=0.5;
//  for(int i=0;i<1;i++) {
//    out = sqrt((out + _prev) / ( in * 1 ) );
//  }
//  println(out);
  
  processImage();
}

void prepareFilters(float[][] f) {
  filterchain.clear();
  Piper p = isr;
//  println("Filters:");
  for(int i = 0; i<f.length;i++) {
    afilter = createFilter((int)f[i][0],p,f[i][1]);
 //   println("-> " + afilter.getClass().getName());
    p = afilter;
    filterchain.add(afilter);
  }
 // println("");
}

void reinitFilters() {
  Piper p = isr;
  for(AFilter f: filterchain) {
    f.reader = p;
    f.initialize();
    p = f;
  }
}

void randomizeConfig() {
  make_equalize = random(1)<0.8;
  for(AFilter f : filterchain) f.randomize();
  resetStreams();
}

void randomizeFilters() {
  int filterno = (int)random(1,4); // 1, 2 or 3 filters in chain
  filters = new float[filterno][2];
  for(int i=0;i<filterno;i++) {
    filters[i][0] = (int)random(MAX_FILTERS);
    filters[i][1] = random(1)<0.5?44100.0:random(1)<0.334?22050:random(1)<0.5?100000:random(3000,120000);
  }
  prepareFilters(filters);
  resetStreams();  
}

void randomizeRaw() {
  boolean keepsame = random(1)<0.5;
  w_rawtype = r_rawtype = random(1)<0.5?INTERLEAVED:PLANAR;
  w_law = r_law = random(1)<0.334?NONE:random(1)<0.5?A_LAW:U_LAW;
  w_sign = r_sign = random(1)<0.5?SIGNED:UNSIGNED;
  w_bits = r_bits = random(1)<0.334?B8:random(1)<0.5?B16:B24;
  w_endianess = r_endianess = random(1)<0.5?BIG_ENDIAN:LITTLE_ENDIAN;
  w_colorspace = r_colorspace = (int)(1000+random(MAX_COLORSPACES+1));
  isr = new RawReader(img.get(), r_rawtype, r_law, r_sign, r_bits, r_endianess);
  isr.r.convertColorspace(r_colorspace);
  if(!keepsame) {
    w_rawtype = random(1)<0.5 ? (random(1)<0.5?INTERLEAVED:PLANAR) : r_rawtype;
    w_law = random(1)<0.334?NONE:random(1)<0.5?A_LAW:U_LAW;
    w_sign = random(1)<0.5?SIGNED:UNSIGNED;
    w_bits = random(1)<0.2 ? (random(1)<0.334?B8:random(1)<0.5?B16:B24) : r_bits;
    w_endianess = random(1)<0.5?BIG_ENDIAN:LITTLE_ENDIAN;
    w_colorspace = (int)(1000+random(MAX_COLORSPACES+1));
  }
  isw = new RawWriter(img.get(), w_rawtype, w_law, w_sign, w_bits, w_endianess);
  reinitFilters();
  resetStreams();
}

String bString(boolean v) { return v?"true":"false";}
void printConfig() {
  println("");
  println("*****************");
  println("General settings:");
  println("  * equalize and normalize histogram: " + bString(make_equalize));
  println("Read image as RAW/WAV:");
  println("  * RAW type: " + getFormatName(r_rawtype));
  println("  * Number format: " + r_bits + " bits, " + getSignName(r_sign));
  println("  * Endianess: " + getEndianName(r_endianess));
  println("  * LAW filtering: " + getLawName(r_law));
  println("  * colorspace: " + getCSName(r_colorspace));
  
  println("Write image as RAW/WAV:");
  println("  * RAW type: " + getFormatName(w_rawtype));
  println("  * Number format: " + w_bits + " bits, " + getSignName(w_sign));
  println("  * Endianess: " + getEndianName(w_endianess));
  println("  * LAW filtering: " + getLawName(w_law));
  println("  * colorspace: " + getCSName(w_colorspace));
  
  println("Filters used:");
  for(AFilter f: filterchain) {
    println("  * " + f.getClass().getName() + ", sample rate: "+f.srate);
  }
  
  println("Filters config:");
  for(AFilter f: filterchain) {
    println("--Config for "+ f.getClass().getName() + ":");
    println(f.toString());
  }
}

void draw() {
  // fill for iterative processing
}

void processImage() {
  printConfig();
  buffer.beginDraw();
  
  // process every byte
  while(!isr.r.taken) isw.write(afilter.read());
  
  // change result colorspace
  isw.w.convertColorspace(w_colorspace);
  // equalize and normalize histogram
  if(make_equalize)
    equalize(isw.w.wimg.pixels);
    
  isw.w.wimg.updatePixels();

  buffer.image(isw.w.wimg, 0, 0);

  if(do_blend)
    buffer.blend(img,0,0,img.width,img.height,0,0,buffer.width,buffer.height,blend_mode);
    
  buffer.endDraw();
  image(buffer,0,0,width,height);
}

void resetStreams() {
  isr.reset();
  isw.reset();
}

void mouseClicked() {
  randomizeConfig();
  processImage();
}

void keyPressed() {
  // SPACE to save
  if(keyCode == 32) {
    String fn = foldername + filename + "/res_" + sessionid + hex((int)random(0xffff),4)+"_"+filename+fileext;
    buffer.save(fn);
    println("Image "+ fn + " saved");
  }
  if(key == 'r') {
    randomizeRaw();
    processImage();
  }
  if(key == 'f') {
    randomizeFilters();
    processImage();
  }
  if(key == 'c') {
    mouseClicked();
  }
}

//

final static int[] blends = {ADD, SUBTRACT, DARKEST, LIGHTEST, DIFFERENCE, EXCLUSION, MULTIPLY, SCREEN, OVERLAY, HARD_LIGHT, SOFT_LIGHT, DODGE, BURN};

// ANIMATION
//
//float p1 = random(TWO_PI);
//float p2 = random(TWO_PI);
//float p3 = random(TWO_PI);
//float p4 = random(TWO_PI);
//float p5 = random(TWO_PI);
//float ang = 0;

//void draw() {
  /* 
   background(0);
   vcf303.env_mod = sin(ang+p1);
   vcf303.cutoff = sin(ang+p2);
   vcf303.resonance = sin(ang+p3);
   vcf303.decay = sin(ang+p4)+0.5;
   vcf303.initialize();
   
   cdelay.ltr_time = map( sin(ang+p1),-1,1,0.1,0.6);
   cdelay.rtl_time = map( sin(ang+p2),-1,1,0.1,0.5);
   cdelay.ltr_feedback = sin(ang+p3);
   cdelay.rtl_feedback = sin(ang+p4);
   cdelay.cutoff = map(sin(ang+p5),-1,1,100,10000);
   cdelay.initialize();
   
   for(int i=0; i<img.width*img.height*3;i++) {
   isw.write(afilter.read());
   }
   
   equalize(isw.w.wimg.pixels);
   isw.w.wimg.updatePixels();
   
   image(isw.w.wimg,0,0);
   
   isr.reset();
   isw.reset();
   ang+=TWO_PI/60.0;
   if(ang<TWO_PI) {
   //  saveFrame("goham/frames_"+(100+frameCount)+".jpg");
   }
   */
//}
