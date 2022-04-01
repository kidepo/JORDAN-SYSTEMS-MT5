//+------------------------------------------------------------------+
//|                                               ATR Trail Stop.mq4 |
//+------------------------------------------------------------------+

//---- indicator settings
#property  indicator_chart_window
#property  indicator_buffers 2
#property indicator_plots   2

#property  indicator_color1  RoyalBlue
#property  indicator_width1  0
#property  indicator_style1  0
#property  indicator_color2  Red
#property  indicator_width2  0
#property  indicator_style2  0

#property indicator_type1   DRAW_ARROW
#property indicator_type2   DRAW_ARROW


//---- indicator parameters
input int BackPeriod = 2000;
input int ATRPeriod = 20;
input double Factor = 2;
input bool MedianPrice = true;
input bool MedianBase = true;
input bool CloseBase = false;
input double distance = 0;

//---- indicator buffers
double     ind_buffer1[];
double     ind_buffer2[];
double     ini=50000;
int   atr;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
  {
//---- drawing settings  
   //SetIndexStyle(0,DRAW_LINE,EMPTY,2);
   //SetIndexStyle(0, DRAW_ARROW);
   
   
   ArraySetAsSeries(ind_buffer1,true); 
   ArraySetAsSeries(ind_buffer2,true); 
   
   //SetIndexArrow(0, 159);
   PlotIndexSetInteger(0,PLOT_ARROW,159);
   
   //SetIndexDrawBegin(0,ATRPeriod);
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ATRPeriod);
   SetIndexBuffer(0,ind_buffer1,INDICATOR_DATA);
   //SetIndexStyle(1,DRAW_LINE,EMPTY,2);
   //SetIndexStyle(1, DRAW_ARROW);
   //SetIndexArrow(1, 159);
   PlotIndexSetInteger(1,PLOT_ARROW,159);

   //SetIndexDrawBegin(1,ATRPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ATRPeriod);
   SetIndexBuffer(1,ind_buffer2,INDICATOR_DATA);

	IndicatorSetInteger(INDICATOR_DIGITS,_Digits+2);
//---- name for DataWindow and indicator subwindow label
   //IndicatorShortName("ATR Stop("+ATRPeriod+" * "+Factor+")");
	IndicatorSetString(INDICATOR_SHORTNAME,"ATR Stop("+ATRPeriod+" * "+Factor+")");
	PlotIndexSetString(0,PLOT_LABEL,"Support");
	PlotIndexSetString(1,PLOT_LABEL,"Resistance");
//---- initialization done

	atr = iATR(NULL,0,ATRPeriod);

  }
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   indicatorCalc(rates_total,prev_calculated,open,high,low,close); 

   return(rates_total);
}
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int indicatorCalc(int rates_total,int prev_calculated,
const double &open[],const double &high[],const double &low[],const double &close[])
  {
   int limit;
   int counted_bars=prev_calculated;
   double PrevUp, PrevDn;
   double CurrUp, CurrDn;
   double PriceCurr, PricePrev;
   double PriceLvl;
   double PriceHLorC;
   double LvlUp = 0;
   double LvlDn = ini;
   int Dir = 1;
   int InitDir;
//---- check for possible errors
   if(counted_bars<0) return(-1);
//---- last counted bar will be recounted
   //if(counted_bars>0) counted_bars--;
   if(counted_bars==0) counted_bars++;
   if (BackPeriod==0) limit=Bars(_Symbol,_Period)-counted_bars-2; else limit=BackPeriod;
//---- fill in buffervalues
   InitDir = 0;
   
	
	double _atr[];
	ArraySetAsSeries(_atr, true);
	if (CopyBuffer(atr,0,0,rates_total,_atr) < 0){Print("CopyBufferATR error =",GetLastError());}
	
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied=CopyRates(Symbol(),Period(),0,Bars(Symbol(),Period()),rates); // Copied all datas
   
   if(ArrayRange(rates,0) <= 1){return(0);}

   
   for(int i=limit; i>0; i--)
   {
      if (MedianPrice) PriceLvl = (rates[i].high + rates[i].low)/2;
      else PriceLvl = rates[i].close;  
      
      if (MedianBase) {
          PriceCurr = (rates[i].high + rates[i].low)/2;
          PricePrev = (rates[i-1].high + rates[i-1].low)/2;
          }
      else {
          PriceCurr = rates[i].close;
          PricePrev = rates[i-1].close;
         }
      
      if(InitDir == 0) {
         CurrUp=PriceCurr - (_atr[i] * Factor);
         PrevUp=PricePrev - (_atr[i-1] * Factor);
         CurrDn=PriceCurr + (_atr[i] * Factor);
         PrevDn=PricePrev + (_atr[i-1] * Factor);
           
         if (CurrUp > PrevUp) Dir = 1;
         LvlUp = CurrUp;
         if (CurrDn < PrevDn) Dir = -1;
         LvlDn = CurrDn;
         InitDir = 1;
       
      }
      
      CurrUp=PriceLvl - (_atr[i] * Factor);
      CurrDn=PriceLvl + (_atr[i] * Factor);
      
      //if (i==0) Comment("Dir:",Dir,",CurrUp:",CurrUp,",PrevUp:",PrevUp,",CurrDn:",CurrDn,",PrevDn:",PrevDn);
      if (Dir == 1) {
         if (CurrUp > LvlUp) {
            ind_buffer1[i] = CurrUp-distance;
            LvlUp = CurrUp;
         }
         else {
            ind_buffer1[i] = LvlUp-distance;
         }
         ind_buffer2[i] = EMPTY_VALUE;
         if (CloseBase) PriceHLorC = rates[i].close; else PriceHLorC=rates[i].low;
         if (PriceHLorC < ind_buffer1[i]) {
            Dir = -1;
            LvlDn = ini;
         }
      }
      
      if (Dir == -1) {
         if (CurrDn < LvlDn) {
            ind_buffer2[i] = CurrDn+distance;
            LvlDn = CurrDn;
         }
         else {
            ind_buffer2[i] = LvlDn+distance;
         }
         ind_buffer1[i] = EMPTY_VALUE;
         if (CloseBase) PriceHLorC = rates[i].close; else PriceHLorC=rates[i].high;
         if (PriceHLorC > ind_buffer2[i]) {
            Dir = 1;
            LvlUp = 0;
         }
      }
      
      if (Dir == 1) {
         if (CurrUp > LvlUp) {
            ind_buffer1[i] = CurrUp-distance;
            LvlUp = CurrUp;
         }
         else {
            ind_buffer1[i] = LvlUp-distance;
         }
         ind_buffer2[i] = EMPTY_VALUE;
         if (CloseBase) PriceHLorC = rates[i].close; else PriceHLorC=rates[i].low;
         if (PriceHLorC < ind_buffer1[i]) {
            Dir = -1;
            LvlDn = ini;
         }
      }
      
      //if (ind_buffer1[0]!=EMPTY_VALUE && ind_buffer1[1]==EMPTY_VALUE) {ind_buffer1[i+1]=ind_buffer1[i];}
      //if (ind_buffer2[0]!=EMPTY_VALUE && ind_buffer2[1]==EMPTY_VALUE) {ind_buffer2[i+1]=ind_buffer2[i];}
 
   }  
   

//---- done
   return(0);
  }