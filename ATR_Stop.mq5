//+------------------------------------------------------------------+
//|                                                   BAT ATR v2.mq4 |
//+------------------------------------------------------------------+
#property  copyright "Copyright Team Aphid"
#property  link      ""
//---- indicator settings
#property  indicator_chart_window
#property  indicator_buffers 3
#property indicator_plots   3
#property  indicator_color1  RoyalBlue
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_ARROW
#property  indicator_color2  Red
#property  indicator_color3  255255255
#property  indicator_width3  1

#define EMPV	-1

//---- indicator parameters
input int ATRPeriod = 20;
input double Factor = 2;
input bool MedianPrice = true;
input bool MedianBase = true;
input bool CloseBase = false;
input double distance = 0.0;

//---- indicator buffers
double     up_line[];
double     dn_line[];
double     sig_dot[];
int   atr;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
	//---- drawing settings  

   ArraySetAsSeries(up_line,true); 
   ArraySetAsSeries(dn_line,true); 
   ArraySetAsSeries(sig_dot,true); 

	SetIndexBuffer(0,up_line,INDICATOR_DATA);
	SetIndexBuffer(1,dn_line,INDICATOR_DATA);
	SetIndexBuffer(2,sig_dot,INDICATOR_DATA);


	//SetIndexDrawBegin(0,ATRPeriod);
	//SetIndexDrawBegin(1,ATRPeriod);
	//SetIndexDrawBegin(2,ATRPeriod);
	
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,ATRPeriod);
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,ATRPeriod);
   PlotIndexSetInteger(2,PLOT_DRAW_BEGIN,ATRPeriod);
	
	
	//SetIndexEmptyValue(0,EMPV);
	//SetIndexEmptyValue(1,EMPV);
   //SetIndexEmptyValue(2,EMPV);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPV);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPV);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPV);
	
	PlotIndexSetInteger(2,PLOT_ARROW,108);

	//IndicatorDigits(MarketInfo(Symbol(),MODE_DIGITS)+2);
	IndicatorSetInteger(INDICATOR_DIGITS,_Digits+2);

	//---- name for DataWindow and indicator subwindow label
	//IndicatorShortName("BAT ATR("+ATRPeriod+" * "+Factor+")");
	IndicatorSetString(INDICATOR_SHORTNAME,"BAT ATR("+ATRPeriod+" * "+Factor+")");
	
	//SetIndexLabel(0,"Support");
	//SetIndexLabel(1,"Resistance");
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
	int counted_bars=prev_calculated;
	int limit;
	static int dir=1;
	double PrevUp, PrevDn;
	double CurrUp, CurrDn;
	double PriceLvl;
	double PriceHLorC;
	static double LvlUp=0,LvlDn=100000;
	
	
	
	//---- check for possible errors
	if (counted_bars<0) return(-1);
	//---- last counted bar will be recounted
	if (counted_bars>=ATRPeriod) limit=Bars(_Symbol,_Period)-counted_bars;
	else limit=Bars(_Symbol,_Period)-ATRPeriod-2;
	if (limit<0) return (-1);
	
	
	double _atr[];
	ArraySetAsSeries(_atr, true);
	if (CopyBuffer(atr,0,0,rates_total,_atr) < 0){Print("CopyBufferATR error =",GetLastError());}
	
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int copied=CopyRates(Symbol(),Period(),0,Bars(Symbol(),Period()),rates); // Copied all datas
	
	   if(ArrayRange(rates,0) <= 1){return(0);}

	//---- fill in buffervalues
	for(int i=limit; i>0; i--) {
		if (MedianPrice) PriceLvl = (rates[i].high + rates[i].low)/2;
		else PriceLvl = rates[i].close;  
		
		
		CurrUp=PriceLvl - (_atr[i] * Factor);
		CurrDn=PriceLvl + (_atr[i] * Factor);

		up_line[i]=EMPV;
		dn_line[i]=EMPV;
		sig_dot[i]=EMPV;

		if (dir>0) {
			if (CloseBase) PriceHLorC = rates[i].close; else PriceHLorC=rates[i].low;
			if (PriceHLorC<LvlUp) {
				dir=-1;
				LvlDn=CurrDn;
				dn_line[i]=LvlDn+distance;
				sig_dot[i]=LvlDn+distance;
			} else {
				if (CurrUp>LvlUp) LvlUp=CurrUp;
				up_line[i] = LvlUp-distance;
			}
		} else {
			if (CloseBase) PriceHLorC = rates[i].close; else PriceHLorC=rates[i].high;
			if (PriceHLorC>LvlDn) {
				dir=1;
				LvlUp=CurrUp;
				up_line[i]=LvlUp-distance;
				sig_dot[i]=LvlUp-distance;
			} else {
				if (CurrDn<LvlDn) LvlDn=CurrDn;
				dn_line[i] = LvlDn+distance;
			}
		}
	}
	sig_dot[0]=EMPV;
	CurrUp=PriceLvl - (_atr[0] * Factor);
	CurrDn=PriceLvl + (_atr[0] * Factor);
	if (dir>0) {
		if (CloseBase) PriceHLorC = rates[0].close; else PriceHLorC=rates[0].low;
		if (PriceHLorC<LvlUp) {
			dn_line[0]=CurrDn+distance;
			sig_dot[0]=CurrDn+distance;
		} else {
			if (CurrUp>LvlUp) up_line[0] = CurrUp-distance;
			up_line[0] = LvlUp-distance;
		}
	} else {
		if (CloseBase) PriceHLorC = rates[0].close; else PriceHLorC=rates[0].high;
		if (PriceHLorC>LvlDn) {
			up_line[0]=CurrUp-distance;
			sig_dot[0]=CurrUp-distance;
		} else {
			if (CurrDn<LvlDn) dn_line[0] = CurrDn+distance;
			dn_line[0] = LvlDn+distance;
		}
	}
	//---- done
	//if(!printOnce){Print(rates[0].close);printOnce = true;}
	return(0);
}