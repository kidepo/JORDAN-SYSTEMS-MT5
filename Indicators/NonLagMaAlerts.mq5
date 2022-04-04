//------------------------------------------------------------------
#property copyright "www.soscode.com"
#property link      "www.soscode.com"
//------------------------------------------------------------------

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   1
#property indicator_label1  "NonLag ma soscode hybrid"
#property indicator_type1   DRAW_COLOR_LINE
#property indicator_color1  Lime,Red,White
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//
//
//
//
//
//
double nonlagma[];
double colorBuffer[];


//extern string TimeFrame = "Current time frame";
input ENUM_TIMEFRAMES timeFrame = NULL;
input int    NlmPeriod = 200;
input int    NlmPrice  = PRICE_CLOSE;
input double PctFilter = 0;
input int    Shift     = 0;
input bool   alertsOn        = true;
input bool   alertsOnCurrent = false;
input bool   alertsMessage   = true;
input bool   alertsSound     = true;
input bool   alertsEmail     = false;


//
//
//
//
//
int Length;
double nlmDa[];
double nlmDb[];
double trend[];
double nlm[];

string indicatorFileName;
bool   returnBars;
bool   calculateValue;
//int    timeFrame;
int MA;
int loopBack;
//------------------------------------------------------------------
//
//------------------------------------------------------------------
//
//
//
//
//

void OnInit()
{
   Length = NlmPeriod;
   SetIndexBuffer(0,nonlagma,INDICATOR_DATA); PlotIndexSetInteger(0,PLOT_COLOR_INDEXES,3);
   SetIndexBuffer(1,colorBuffer,INDICATOR_COLOR_INDEX); 
   SetIndexBuffer(2,trend,INDICATOR_CALCULATIONS); 
   IndicatorSetString(INDICATOR_SHORTNAME,"NonLag ma ("+string(Length)+")");

}
int OnDeinit()
{
   return(0);
}
//------------------------------------------------------------------
//
//
//
//
//

double work[][2];
#define _change 0
#define _achang 1

int Bars = Bars(_Symbol,_Period);

int OnCalculate (const int rates_total,
                 const int prev_calculated,
                 const int begin,
                 const double& price[] )
{
   for (int i=(int)MathMax(prev_calculated-1,0); i<rates_total; i++)
   {
      nonlagma[i] = iNoLagMa(price[i],Length,i,0);
      if (i>0)
      {
         colorBuffer[i] = 2;
            if (nonlagma[i]>nonlagma[i-1]) {colorBuffer[i]=0;trend[i] =  1;}
            if (nonlagma[i]<nonlagma[i-1]) {colorBuffer[i]=1;trend[i] =  -1;}
      }
   }      
   return(rates_total);
}



//-------------------------------------------------------------------
//                                                                  
//-------------------------------------------------------------------
//
//
//
//
//

void manageAlerts()
{
   int whichBar;
   if (alertsOn)
   {
      if (alertsOnCurrent)
           whichBar = 0;
      else     whichBar = 1;
      if (trend[whichBar] != trend[whichBar+1])
      {
         if (trend[whichBar] ==  1) doAlert(whichBar,"up");
         if (trend[whichBar] == -1) doAlert(whichBar,"down");
      }
   }
}

//
//
//
//
//

void doAlert(int forBar, string doWhat)
{
   static string   previousAlert="nothing";
   static datetime previousTime;
   string message;
   
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied=CopyRates(Symbol(),Period(),0,Bars(Symbol(),Period()),rates); // Copied all datas
   
   
   if (previousAlert != doWhat || previousTime != rates[forBar].time) {
       previousAlert  = doWhat;
       previousTime   = rates[forBar].time;

       //
       //
       //
       //
       //

       message =  timeFrameToString(Period())+" "+Symbol()+" at "+TimeToString(TimeLocal(),TIME_SECONDS)+" NonLag ma trend changed to "+doWhat;
          if (alertsMessage) Alert(message);
          if (alertsEmail)   SendMail(Symbol()+" NonLagMA",message);
          if (alertsSound)   PlaySound("alert2.wav");
   }
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

#define Pi       3.14159265358979323846264338327950288
#define _length  0
#define _len     1
#define _weight  2

double  nlm_values[3][1];
double  nlm_prices[ ][1];
double  nlm_alphas[ ][1];

//
//
//
//
//

double iNoLagMa(double price, int length, int r, int forValue=0)
{
   if (ArrayRange(nlm_prices,0) != Bars(Symbol(),0)) {ArrayResize(nlm_prices,Bars(Symbol(),0));}
                               if(ArrayRange(nlm_prices,0) <= 1){return(0);}
                               nlm_prices[r][forValue]=price;
   if (length<3 || r<3) return(nlm_prices[r][forValue]);
   
   //
   //
   //
   //
   //
   
   if (nlm_values[_length][forValue] != length)
   {
      double Cycle = 4.0;
      double Coeff = 3.0*Pi;
      int    Phase = length-1;
      
         nlm_values[_length][forValue] = length;
         nlm_values[_len   ][forValue] = length*4 + Phase;  
         nlm_values[_weight][forValue] = 0;

         if (ArrayRange(nlm_alphas,0) < nlm_values[_len][forValue]) ArrayResize(nlm_alphas,(int)nlm_values[_len][forValue]);
         for (int k=0; k<nlm_values[_len][forValue]; k++)
         {
            double t;
            if (k<=Phase-1) 
                 t = 1.0 * k/(Phase-1);
            else t = 1.0 + (k-Phase+1)*(2.0*Cycle-1.0)/(Cycle*length-1.0); 
            double beta = MathCos(Pi*t);
            double g = 1.0/(Coeff*t+1); if (t <= 0.5 ) g = 1;
      
            nlm_alphas[k][forValue]        = g * beta;
            nlm_values[_weight][forValue] += nlm_alphas[k][forValue];
         }
   }
   
   //
   //
   //
   //
   //
   
   if (nlm_values[_weight][forValue]>0)
   {
      double sum = 0;
           for (int k=0; k < nlm_values[_len][forValue] && (r-k)>=0; k++) sum += nlm_alphas[k][forValue]*nlm_prices[r-k][forValue];
           return( sum / nlm_values[_weight][forValue]);
   }
   else return(0);           
}
//
//-------------------------------------------------------------------
//
//
//
//
//

void CleanPoint(int i,double& first[],double& second[])
{
   if ((second[i]  != EMPTY_VALUE) && (second[i+1] != EMPTY_VALUE))
        second[i+1] = EMPTY_VALUE;
   else
      if ((first[i] != EMPTY_VALUE) && (first[i+1] != EMPTY_VALUE) && (first[i+2] == EMPTY_VALUE))
          first[i+1] = EMPTY_VALUE;
}

//
//
//
//
//

void PlotPoint(int i,double& first[],double& second[],double& from[])
{
   if (first[i+1] == EMPTY_VALUE)
      {
         if (first[i+2] == EMPTY_VALUE) {
                first[i]   = from[i];
                first[i+1] = from[i+1];
                second[i]  = EMPTY_VALUE;
            }
         else {
                second[i]   =  from[i];
                second[i+1] =  from[i+1];
                first[i]    = EMPTY_VALUE;
            }
      }
   else
      {
         first[i]  = from[i];
         second[i] = EMPTY_VALUE;
      }
}

//-------------------------------------------------------------------
//
//-------------------------------------------------------------------
//
//
//
//
//

string sTfTable[] = {"M1","M5","M15","M30","H1","H4","D1","W1","MN"};
int    iTfTable[] = {1,5,15,30,60,240,1440,10080,43200};

//
//
//
//
//

int stringToTimeFrame(string tfs)
{
   tfs = stringUpperCase(tfs);
   for (int i=ArraySize(iTfTable)-1; i>=0; i--)
         if (tfs==sTfTable[i] || tfs==""+iTfTable[i]) return(MathMax(iTfTable[i],Period()));
                                                      return(Period());
}
string timeFrameToString(int tf)
{
   for (int i=ArraySize(iTfTable)-1; i>=0; i--) 
         if (tf==iTfTable[i]) return(sTfTable[i]);
                              return("");
}

//
//
//
//
//

string stringUpperCase(string str)
{
   string   s = str;

   for (int length=StringLen(str)-1; length>=0; length--)
   {
      int charf = StringGetCharacter(s, length);
         if((charf > 96 && charf < 123) || (charf > 223 && charf < 256))
                     s = StringSetCharacter(s, length, charf - 32);
         else if(charf > -33 && charf < 0)
                     s = StringSetCharacter(s, length, charf + 224);
   }
   return(s);
}