#property copyright "Jordan Capital Inc."
#property link      "https://www.jordancapital.com"
#property version   "2022.12.12@15:50"
/*
Added Sonic Trend Signal As SYSTEM 4//SupersonicTrendSignal
----------------------------------------
*Static target re-calculation in drawdown
*Add BC Volume Area to filter trades on range
Enable multi-asset trading(trd closing, target re-calcualtions )
Break even when profit return to 0.0 from drawdown
Break even when first normal target reached -->
Break even when the advanced target has been reached
Take screen shot on open and close of trade for journaling
Added Elliot Wave Oscillator
---consider adding fibo levels for profits
---no enter trades when current trade still running (consider stops)
---set break even levels a draw of fibo
+++
--select to find existing position so as to break even, avoid position not found
--check if to close by cash by first determining if the current postions have take profit set or not
*/

#include <Mql5Book\Trade.mqh>
CTradeC Trade;
#include <Trade\XTrade.mqh>
//#include <Mql5Book\XTrade.mqh>
CTrade TradeX;

// Timer
#include <Mql5Book\Timer.mqh>
CTimer Timer;
CNewBar NewBar;

// Price
#include <Mql5Book\Price.mqh>
CBars Price;

#include <Mql5Book\MoneyManagement.mqh>

#include <Mql5Book\TrailingStops.mqh>
CTrailing Trail;

input bool PlaceTradesInPut = true;
input int MyMagicNumber = 0;

sinput string strategy_1_4MA;
input bool ActivateSys1_ = false;
input int MAPeriodShort=2;
/*10/smooth*/
input int MAPeriodLong=200;
input int FourMAPeriod=200;

sinput string __strategy_2_NonLag;	
input bool ActivateSys2_ = false;
input int NonLagMAPeriod=200;
input bool confirmByNonlag = false;

sinput string ____________;
input int MAShift=0;
input ENUM_MA_METHOD MAMethodS= MODE_SMMA;
input ENUM_MA_METHOD MAMethodL= MODE_EMA;
input ENUM_APPLIED_PRICE MAPrice= PRICE_CLOSE;
sinput string _____________;

sinput string __strategy_3_BCVArea;	
input bool ActivateSys3_ = false;
input double BCVolumeAreaSignalVal = 200;
input int BCVolumeAreaCandleSeq = 0;
input bool UseElliotWaveOscillator = false;
input string ElliotWaveOscillatorName = "Elliott Wave Oscillator-2-200";
input int                  EWOFastMA = 2;                                            
input int                  EWOSlowMA = 200; 
input int                  EWOCandleSeq = 1;                                          
input ENUM_APPLIED_PRICE   EWOPriceSource = PRICE_MEDIAN;                            
input ENUM_MA_METHOD       EWOSmoothingMethod = MODE_SMMA;
sinput string strategy_4_SonicTrend;
input bool ActivateSys4_ = true;
input int SonicBarIndex = 0;
input int SonicTrendValue = 100;
input int SoniciFullPeriods = 1;
input int Sonic3param = 0;
input bool AllowSonicStopLevel = true;
input int SonicStopMAValue = 50;
input ENUM_MA_METHOD SonicMAMethod= MODE_SMMA;
input ENUM_APPLIED_PRICE SonicMAPrice= PRICE_CLOSE;

sinput string __filters__;	
input bool UseBCVolumeAreaFilter = true;
input double BCVolumeAreaFilterVal = 100;
sinput string MoneyManagement;	
input double AllowedPriceGap = 0.0;	
input double volume=0.01;
input bool UseMoneyManagement = true;
sinput string PointsMeasures;
input double RiskPercent = 2;
input double StopLoss = 0.0;
input double TakeProfit = 0.0;

sinput string CashMeasures;
input bool UseTakeProfitCash=true;
input double takeProfitCash_=5.0;
input double takeProfitCashLongs_=20.0;
input double DailyProfitCash=40.0;
input double lossToStopDayTrading=10.0;
//input double stopLossCash=0.0;

sinput string PercentageMeasures;
input bool UseTakeProfitPercentage=false;
input double takeProfitPercentage=6.0;
input double takeProfitPercentageLongs=30.0;
input double DailyProfitPercentage=50;
input double PercentagelossToStopDayTrading = 10;
//input double stopLossPercentage=0.0;
//input bool TradeLongsOnce=true;


input bool AllSymbols = false;
input bool TradeOnEveryTick = false;
input int MaximumTradeCount = 2;
input int TotalAccMaximumTradeCount = 6;
input int TradeBasketsPerTrend = 1;
input bool miniExitByNonlag = false;

sinput string TradeTypeOptions;	
input bool FullAutoPilot = true;
input bool SellOnly = false;
input bool BuyOnly = false;
input bool TradeImmediately = false;
input bool TradeImmediatelyWithBuy = false;
input bool TradeImmediatelyWithSell = false;
input bool useSteadyProgressRecover = true;
input bool useStaticMoneyRecoverOnEquity = false;
input bool useStaticMoneyRecoverOnBal = false;


sinput string TS;		// Trailing Stop
input bool UseTrailingStop = false;
input int TrailingStop = 0;
input int MinimumProfit = 0;
input int Step = 0; 
sinput string __fibs__;	
input bool AutoStopLossSet = true;
input bool UseFibProfitLevel_ = true;
input double _StopLoss_Fib = 50.0;
input double _BreakEven_Fib = 161.8;
input double _TakeProfit_Fib = 200.0;

sinput string BE__points__;		// Break Even
input bool UseBreakEven = true;
input int BreakEvenProfit_ = 0;
input double LockProfitPercentage = 2;

sinput string ALERTS;		
input bool   alertsOnCurrent = false;
input bool   alertsMessage   = false;
input bool   alertsOnPhone   = true;
input bool   alertsEmail     = false;
input bool   alertsSound     = false;
input bool   alertsTelegram  = false;
input bool   alertsMiniSignals  = false;
input string     APIkey      = "1819898948:AAFRCYc45DMt_hTjwRtUuk58iRIvc1bRcIs";
input string     Channel_ID  = "-1001860762374";
//-------------------------
string EA_Version = "#JC-Lazy-Trader-v1";



enum orderType{
   orderBuy,
   orderSell
};

datetime candleTimes[],lastCandleTime;
string CurSignal="";
string CurSignalNonLag="";
string CurTrend;
string SonicTrendSignal;
string CurTrendNonLag;
int CandleSeq=1;
int MagicNumber=0;
double onStartEquity=0;
bool innerlocked = false;
//bool closedFalls = false;
//+---trade closing
int RTOTAL=4;       
int SLEEPTIME=1;     
int  Deviation_=10;
long Slippage = 3;
bool TradeOnEveryTickL = false;

double curProfit=0;
double curBal=0;
double curBalProfit=0;
double _4MACandleRange = 0.0;
//int TradeBasketsPerTrendTrack = 0;
bool buyPlaced = true;
bool sellPlaced = true;
double tradeSize;
bool PlaceTrades = true;
double CurrentPriceGapRange = 0.0;
string lastError ="";

double takeProfitCash= takeProfitCash_;
double takeProfitCashLongs= takeProfitCashLongs_;
double highestBalCaptured= 0.0;
double currentEquity= 0.0;
double NextExpectedBal= 0.0;
datetime startTime;

string BCVolumeAreaSignal = "NONE";
string BCVolumeAreaSignalMain = "NONE";
string ActivateSys3FinalSignal = "NONE";
bool ActivateSys3 = ActivateSys3_;
bool ActivateSys2 = ActivateSys2_;
bool ActivateSys1 = ActivateSys1_;
bool ActivateSys4 = ActivateSys4_;
datetime lastBuySignalTime,lastSellSignalTime;

double profitFibLevel = 0.0;
double lossFibLevel = 0.0;
double stopLoss = 0.0;
double takeProfit = 0.0; 
int BreakEvenProfit = BreakEvenProfit_;
//int LockProfitPercentage = LockProfitPercentage_;
int LockProfit = 0;
double stopLossMM = 0.0;
bool UseFibProfitLevel = UseFibProfitLevel_;
bool FibProfitUsed = false;
double sonicSL = 0.0;

MqlTradeRequest request;
MqlTradeResult result;
MqlTradeCheckResult checkResult;

//+------------------------------------------------------------------+ 
//| start function                                                   |
//+------------------------------------------------------------------+
int OnInit(){
//TakeChartScreenShot("Test2");
//Print("Client ACCOUNT_LOGIN = ", AccountInfoInteger(ACCOUNT_LOGIN));
   if(ActivateSys3 || UseBCVolumeAreaFilter){TesterHideIndicators(true);}
   ActivateSys3 = ActivateSys3_;
   ActivateSys2 = ActivateSys2_;
   ActivateSys1 = ActivateSys1_;
   ActivateSys4 =ActivateSys4_;
   UseFibProfitLevel = UseFibProfitLevel_;

	ArraySetAsSeries(candleTimes,true);
	onStartEquity = AccountInfoDouble(ACCOUNT_BALANCE);
	innerlocked = false;
	//closedFalls = false;
	if(TradeImmediatelyWithBuy){
	   if(ActivateSys1)CurSignal = "BUY";
	   if(ActivateSys2)CurSignalNonLag = "BUY";
	   }
	if(TradeImmediatelyWithSell){
	   if(ActivateSys1)CurSignal = "SELL";
	   if(ActivateSys2)CurSignalNonLag = "SELL";
	   }
	if(TradeImmediately){
	    buyPlaced = false;
       sellPlaced = false;
	 }
	   TradeOnEveryTickL  = TradeOnEveryTick;
	   //Print(">>"+_Symbol+"<<");
	   double _4MACandleRange = 0.0;
   //TradeBasketsPerTrendTrack = TradeBasketsPerTrend;
   PlaceTrades = PlaceTradesInPut;
   startTime =TimeLocal();

   if(highestBalCaptured == 0.0){
         highestBalCaptured = AccountInfoDouble(ACCOUNT_BALANCE);
     }
     
   if(ActivateSys1){
      //EA_Version = EA_Version + ":[1]";
   }
   if(ActivateSys2){
      //EA_Version = EA_Version + ":[2]";
   }
   
     if(ActivateSys4){
      ActivateSys2 = false;
      ActivateSys1 = false;
      ActivateSys3 = false;
      
   }
      
   if(ActivateSys3){
      ActivateSys2 = false;
      ActivateSys1 = false;
      ActivateSys4 = false;
      //EA_Version = EA_Version + ":[3]";
   }
   
   if(UseElliotWaveOscillator){
      ActivateSys2 = false;
      ActivateSys1 = false;
      ActivateSys3 = true;
      ActivateSys4 = false;
      //EA_Version = EA_Version + ":[4]";
   }
 
   
    buyPlaced = true;
    sellPlaced = true;
    
    //Setting stoplevels
	   stopLoss = StopLoss;
	   takeProfit = TakeProfit;
   
	return(0);
}

void OnTickT(){
//--- obtain spread from the symbol properties
   bool spreadfloat=SymbolInfoInteger(Symbol(),SYMBOL_SPREAD_FLOAT);
   string comm=StringFormat("Spread %s = %I64d points\r\n",
                            spreadfloat?"floating":"fixed",
                            SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));
//--- now let's calculate the spread by ourselves
   double ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   double spread=ask-bid;
   int spread_points=(int)MathRound(spread/SymbolInfoDouble(Symbol(),SYMBOL_POINT));
   comm=comm+"Calculated spread = "+(string)spread_points+" points";
   Comment(comm);
   Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
}

void OnTick(){
//Calculate Profits
currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
curBal = AccountInfoDouble(ACCOUNT_BALANCE);

curProfit = NormalizeDouble((currentEquity - onStartEquity),_Digits);
curBalProfit = NormalizeDouble((curBal - onStartEquity),_Digits);

Comment("Copyright © 2023 Jordan Capital Inc. ["+MagicNumber+"], Loaded @ "+startTime+",\nStart Bal. "+onStartEquity+" Cur Bal. "+curBal+" Bal Profit. "+curBalProfit+" Peak Bal. "+highestBalCaptured+"\nCur EQt. "+ currentEquity +", Flt Profit. "+curProfit+"\nTrade Target: "+ takeProfitCash +"\nDaily;- Target: "+ DailyProfitCash +", Loss: "+lossToStopDayTrading+"\n\n"+
    "SYS 1: "+CurTrend+"<--4MACandles (Active-"+ActivateSys1+") \nSYS 2: "+CurTrendNonLag+ "<--Non lag (Active-"+ActivateSys2+")\nSYS 3: "+ActivateSys3FinalSignal+ "<--J.C.I (Active-"+ActivateSys3+" [EWO-"+UseElliotWaveOscillator+", BCAVol-"+!UseElliotWaveOscillator+" | Signal- "+BCVolumeAreaSignalMain+"])* \nSYS 4: "+SonicTrendSignal+"<--SONIC TREND [Default] (Active-"+ActivateSys4+") \n\n"+
    "Filter: "+BCVolumeAreaSignal+" ... (Active-"+UseBCVolumeAreaFilter+")\nInner Locked: "+innerlocked+"\nPlace Trades: "+PlaceTrades+"\nPrice Gap: "+CurrentPriceGapRange+" (Allowed - "+AllowedPriceGap+")\n"+lastError);
//modify targets
if(useStaticMoneyRecoverOnEquity){
   if(curProfit < 0){//if we are in drawdown
      takeProfitCash = takeProfitCash_ + MathAbs(curProfit);
      takeProfitCashLongs = takeProfitCashLongs_ + MathAbs(curProfit);
      UseFibProfitLevel = false;//switch off fib target
   }else{
      takeProfitCash = takeProfitCash_;
      takeProfitCashLongs = takeProfitCashLongs_;
      UseFibProfitLevel = true;//switch on fib target
   }
}else if(useStaticMoneyRecoverOnBal){
       if(curBalProfit < 0){//if we are in drawdown
         takeProfitCash = takeProfitCash_ + MathAbs(curBalProfit);
         takeProfitCashLongs = takeProfitCashLongs_ + MathAbs(curBalProfit);
         UseFibProfitLevel = false;//switch off fib target
        }else {
         takeProfitCash = takeProfitCash_;
         takeProfitCashLongs = takeProfitCashLongs_;
         UseFibProfitLevel = true;//switch on fib target
       }
}else if(useSteadyProgressRecover){//recover any drawdown even in positive
      if(highestBalCaptured == 0.0){
            highestBalCaptured = curBal;
      }else if(curBal > highestBalCaptured ){
         highestBalCaptured = curBal;
      }
      //if cur bal goes below highest covered
      if(curBal < highestBalCaptured){
         double new_adv_target = MathAbs(highestBalCaptured - curBal);
          takeProfitCash = takeProfitCash_ + MathAbs(new_adv_target);
          takeProfitCashLongs = takeProfitCashLongs_ + MathAbs(new_adv_target);
          UseFibProfitLevel = false;//switch off fib target
      }else{//if curbal is above highBalCaptured or equal, go back to original targets
          takeProfitCash = takeProfitCash_;
          takeProfitCashLongs = takeProfitCashLongs_;
          UseFibProfitLevel = true;//switch on fib target
      }
   
  }


		
// rechecking if magic number is set
   if(MagicNumber <= 0 && MyMagicNumber <= 0)
     {
      MagicNumber = MathAbs(ChartID());
      if(MagicNumber <= 0){
         MagicNumber = MagicNumber * -1;
      }
      printf("MagicNumber AutoSet To => "+ MagicNumber);
     }else if(MyMagicNumber > 0){
      MagicNumber = MyMagicNumber;
     }
  
	
	if(checkNewCandle(candleTimes,lastCandleTime)){//Execute strictly Once on every Candle
	
	   //TakeChartScreenShot("Test");

		
		double maS[];
		double maL[];
		double maSNonLag[];
		double maLNonLag[];
		double NonLagSignalValues[];
		double _4MACandlesValuesH[];
		double _4MACandlesValuesL[];
		double BCVolumeArea[];
		double BCVolumeAreaSig[];
		double SonicTrendSigBuy[];
		double SonicTrendSigSell[];
		double SonicStopMA[];
		ArraySetAsSeries(maS,true);
		ArraySetAsSeries(maL,true);
		ArraySetAsSeries(maSNonLag,true);
		ArraySetAsSeries(maLNonLag,true);
		ArraySetAsSeries(NonLagSignalValues,true);
		ArraySetAsSeries(_4MACandlesValuesH,true);
		ArraySetAsSeries(_4MACandlesValuesL,true);
		ArraySetAsSeries(BCVolumeArea,true);
		ArraySetAsSeries(BCVolumeAreaSig,true);
		ArraySetAsSeries(SonicTrendSigBuy,true);
		ArraySetAsSeries(SonicTrendSigSell,true);
		ArraySetAsSeries(SonicStopMA,true);
		
		double candleClose[];
		ArraySetAsSeries(candleClose,true);
		int maSHandle= iMA(_Symbol,_Period,MAPeriodShort,MAShift,MAMethodS,MAPrice);
		int maLHandle= iMA(_Symbol,_Period,MAPeriodLong,MAShift,MAMethodL,MAPrice);
		//+FOR NONLAG
		int maLHandleNonLag = iCustom(_Symbol,_Period, "NonLagMaAlerts");
		int BCVolumeAreaHandle = 0;
		int BCVolumeAreaSigHandle = 0;
		int maSHandleNonLag= iMA(_Symbol,_Period,10,0,MODE_EMA,MAPrice);
		
		if(UseBCVolumeAreaFilter)//used for filtering, can be any /BC Volume Area or /solarwindsor /Volatility Adjusted WPR-JC
		    BCVolumeAreaHandle = iCustom(_Symbol,_Period, "BC Volume Area", BCVolumeAreaFilterVal);///solarwinds/Volatility Adjusted WPR-JC
		if(ActivateSys3){
		   if(UseElliotWaveOscillator){
		      BCVolumeAreaSigHandle = iCustom(_Symbol,_Period, ElliotWaveOscillatorName);//ElliotWaveOscillator
		    }else{
		      BCVolumeAreaSigHandle = iCustom(_Symbol,_Period, "BC Volume Area", BCVolumeAreaSignalVal);//if not elliot
		    }
		
		}
		//system 4//Sonic Trend System
		int SonicTendHandle = iCustom(_Symbol,_Period, "SupersonicTrendSignal", SonicTrendValue,SoniciFullPeriods,Sonic3param);
		int SonicStopMAHandle= iMA(_Symbol,_Period,SonicStopMAValue,MAShift,SonicMAMethod,SonicMAPrice);
		
		CopyBuffer(maSHandle,0,0,3,maS);
		CopyBuffer(maLHandle,0,0,3,maL);//CopyBuffer(NonlagMaHandle,0,0,3,NonLagSignalValues);
		CopyBuffer(maLHandleNonLag,0,0,3,maLNonLag);//Non Lag Ma
		CopyBuffer(maLHandleNonLag,2,0,3,maLNonLag);//Non Lag Ma Actual Trend
		CopyBuffer(maSHandleNonLag,0,0,3,maSNonLag);//EMa 10
		
		int _4MACandlesHandle = iCustom(_Symbol,_Period, "4MACandles");
		CopyBuffer(_4MACandlesHandle,1,0,3,_4MACandlesValuesH);//Upper
		CopyBuffer(_4MACandlesHandle,2,0,3,_4MACandlesValuesL);//Lower
		_4MACandleRange =MathAbs(_4MACandlesValuesH[0] - _4MACandlesValuesL[0]);
		if(UseBCVolumeAreaFilter)
		   {CopyBuffer(BCVolumeAreaHandle,0,0,5,BCVolumeArea);}
		if(ActivateSys3)
		   {CopyBuffer(BCVolumeAreaSigHandle,0,0,5,BCVolumeAreaSig);}
		CopyBuffer(SonicTendHandle,0,0,3,SonicTrendSigBuy);//Sonic Trend Signal Buy
		CopyBuffer(SonicTendHandle,1,0,3,SonicTrendSigSell);//Sonic Trend Signal Buy
		CopyBuffer(SonicStopMAHandle,0,0,3,SonicStopMA);//SOnic MA to determine stop level
		
		CopyClose(_Symbol,_Period,0,3,candleClose);
		CurrentPriceGapRange = CalculatePriceGap(maL[0]);
		
		
		/*if(UseBCVolumeAreaFilter){
		   if(BCVolumeArea[0] > 0) BCVolumeAreaSignal = "BUY";
		   if(BCVolumeArea[0] < 0) BCVolumeAreaSignal = "SELL";
		}else{
		   BCVolumeAreaSignal = "NONE";
		}*/
		//strengthern signal
		if(UseBCVolumeAreaFilter){
		   if(BCVolumeArea[0] > 0 && BCVolumeArea[1] > 0 && BCVolumeArea[2] > 0 /*&& BCVolumeArea[3] > 0*/) BCVolumeAreaSignal = "BUY";
		   if(BCVolumeArea[0] < 0 && BCVolumeArea[1] < 0 && BCVolumeArea[2] < 0 /*&& BCVolumeArea[3] < 0*/) BCVolumeAreaSignal = "SELL";
		}else{
		   BCVolumeAreaSignal = "NONE";
		}
		
		
		/*if(ActivateSys3){
		   if(BCVolumeAreaSig[0] > 0) BCVolumeAreaSignalMain = "BUY";
		   if(BCVolumeAreaSig[0] < 0) BCVolumeAreaSignalMain = "SELL";
		}else{
		   BCVolumeAreaSignalMain = "NONE";
		}*/
		
      if(ActivateSys1 || ActivateSys2){
      
      		if((maS[CandleSeq+1] < maL[CandleSeq+1])&&(maS[CandleSeq]>maL[CandleSeq])){//update to more accurate cross under method
      			//cross up
      			Print("Cross above!");
      			//closePosition();
      			if(confirmByNonlag && CurSignalNonLag == "BUY"){
         			if(ActivateSys1){
            			 CloseAllTrades("SELL"); 
            			 //TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"SELL" );
            			 //makePosition(orderBuy);
            			 buyPlaced = false;//clear up to all buys
            			 if(ActivateSys1)Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
            			}
            			CurSignal="BUY";
         			}else if(!confirmByNonlag){
            			if(ActivateSys1){
               			CloseAllTrades("SELL");
               			//TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"SELL" );
               			buyPlaced = false; 
               			if(ActivateSys1)Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
               			
            			}
            			CurSignal="BUY";
            		}
      			
      		}else if((maS[CandleSeq+1]>maL[CandleSeq+1])&&(maS[CandleSeq]<maL[CandleSeq])){//update to more accurate cross under method
      			//cross down
      			Print("Cross under!");
      			//closePosition();
      			if(confirmByNonlag && CurSignalNonLag == "SELL"){
         			if(ActivateSys1){
         			   CloseAllTrades("BUY");
         			   //TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"BUY" );
         			   sellPlaced = false;
         			   if(ActivateSys1)Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
         			  }
         			//makePosition(orderSell); 
         			CurSignal="SELL";
         			} else if(!confirmByNonlag){
            			if(ActivateSys1){
               			CloseAllTrades("BUY");
               			//TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"BUY" );
               			sellPlaced = false;
               			if(ActivateSys1)Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
               		} 
            			CurSignal="SELL";
         		} 
      
      		}else if(maS[CandleSeq]>maL[CandleSeq]){//use this for buying
      			CurTrend="BUYING";
      			//if(ActivateSys1)TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"SELL" );//CloseAllTrades("SELL");
      			if(ActivateSys1 && TradeImmediately)CurSignal="BUY";
      		}else if(maS[CandleSeq]<maL[CandleSeq]){
      		   CurTrend="SELLING";
      		   //if(ActivateSys1)TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"BUY" );//CloseAllTrades("BUY");
      		   if(ActivateSys1 && TradeImmediately)CurSignal="SELL";
      		}
      		
      		//FOR NON LAG
      		
      		if((maSNonLag[CandleSeq+1] < maLNonLag[CandleSeq+1])&&(maSNonLag[CandleSeq]>maLNonLag[CandleSeq])){
      			//cross up
      			Print("Cross above for Non Lag!");
      			//closePosition();
      			if(ActivateSys2){
      			   //CloseAllTrades("SELL"); //close all sells
      			   TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"SELL" );
      			   buyPlaced = false;
      			   Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
      			}
      			//makePosition(orderBuy);
      			CurSignalNonLag="BUY";
      
      
      		}else if((maSNonLag[CandleSeq+1]>maLNonLag[CandleSeq+1])&&(maSNonLag[CandleSeq]<maLNonLag[CandleSeq])){
      			//cross down
      			Print("Cross under for Non Lag!");
      			//closePosition();
      			if(ActivateSys2){
      			   //CloseAllTrades("BUY"); //close all buys
      			   TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"BUY");
      			   sellPlaced = false;
      			   Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
      			}
      			//makePosition(orderSell); 
      			CurSignalNonLag="SELL";
      
      		}else if((maSNonLag[CandleSeq]>maLNonLag[CandleSeq])){
      		   CurTrendNonLag="BUYING";
      		   //if(ActivateSys2)TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"SELL" );//CloseAllTrades("SELL");
      			if(ActivateSys2 && TradeImmediately)CurSignalNonLag="BUY"; 
      		}else if((maSNonLag[CandleSeq]<maLNonLag[CandleSeq])){
      		   CurTrendNonLag="SELLING";
      		   //if(ActivateSys2)TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"BUY" );//CloseAllTrades("BUY");
      		   if(ActivateSys2 && TradeImmediately)CurSignalNonLag="SELL"; 
      		}
      		
      		//FOR NON LAG ENDS
		}else if(ActivateSys3){ 
		   if(!UseElliotWaveOscillator){
   		   if(BCVolumeAreaSig[0] > 0 && BCVolumeAreaSig[1] > 0 && BCVolumeAreaSig[2] > 0 && BCVolumeAreaSig[3] > 0 /*&& BCVolumeAreaSig[4] < 0*/) {
   		      
   		      if(BCVolumeAreaSignalMain == "SELL"){
                  	//CloseAllTrades("SELL"); 
                  	//buyPlaced = false;//clear up to all buys
                  	if(alertsMiniSignals)
                  	  {Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);}
               	   //buy here
               	}
               	BCVolumeAreaSignalMain = "BUY";
   
   		   }
   		   
   		   if(BCVolumeAreaSig[0] < 0 && BCVolumeAreaSig[1] < 0 && BCVolumeAreaSig[2] < 0 && BCVolumeAreaSig[3] < 0 /*&& BCVolumeAreaSig[4] > 0*/) {
   		      if(BCVolumeAreaSignalMain == "BUY"){
                  	//CloseAllTrades("BUY"); 
                  	//sellPlaced = false;//clear up to all buys
                  	if(alertsMiniSignals)
                  	{Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);}
               	   //sell here
               	}
               	BCVolumeAreaSignalMain = "SELL";
   		   }
		   }else if(UseElliotWaveOscillator){//Main Course
   		    if(BCVolumeAreaSig[0] > 0 && BCVolumeAreaSig[1] > 0 ) {
      		      
      		      if(BCVolumeAreaSignalMain == "SELL"){
                     	//CloseAllTrades("SELL"); 
                     	//buyPlaced = false;//clear up to all buys
                     	if(alertsMiniSignals)
                     	   {Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);}
                  	   //buy here
                  	}
                  	BCVolumeAreaSignalMain = "BUY";
      
      		   }
      		   
      		   if(BCVolumeAreaSig[0] < 0 && BCVolumeAreaSig[1]) {
      		      if(BCVolumeAreaSignalMain == "BUY"){
                     	//CloseAllTrades("BUY"); 
                     	//sellPlaced = false;//clear up to all buys
                     	if(alertsMiniSignals)
                     	   {Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);}
                  	   //sell here
                  	}
                  	BCVolumeAreaSignalMain = "SELL";
      		   }
		   }
		   
		   //SYSTEM 3 ALERTS
		   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
		   double StopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
		   if(BCVolumeAreaSignalMain =="BUY" && BCVolumeAreaSignal == "BUY"){
		            if(ActivateSys3FinalSignal == "SELL"){
		                  buyPlaced = false;
                        //Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
		                  lastBuySignalTime = getCandleTime(candleTimes,lastCandleTime,0);
		                  
		                  //--------fibs
		                  //for buys get the lowest price  betwwen previous sell, set it to selltrailP
		                  //+ get  number of candles between current signal and last sell
		                  int n_candles = 0;
		                  n_candles =Bars(_Symbol,PERIOD_CURRENT,lastSellSignalTime,lastBuySignalTime);		                  
		                  if(n_candles <= 0 || lastBuySignalTime == "1970.01.01 00:00:00" || lastSellSignalTime == "1970.01.01 00:00:00" || lastSellSignalTime == NULL || lastBuySignalTime == NULL){
		                     n_candles = 200;
		                  }
		                  printf("n_candles=>"+n_candles);
		                  printf("lastBuySignalTime=>"+lastBuySignalTime);
		                  printf("lastBuySignalTime=>"+lastSellSignalTime);
		                  //iBarShift//use this to get left Border of fibo
		                  //+ get the lowest in the series
		                  double lowestP = Price.LowestLow(_Symbol,PERIOD_CURRENT,n_candles,0);
		                  //printf("fib_lowestP");
               		   //printf(lowestP);
		                  
		                  //--Getting Fib Levels
		                  double fib_range = Price.GetFibLevels(lowestP, 0,  0, 0, "BUY");
		                  double fib_261_8 = Trade.NormalizePrice(lowestP + (fib_range*2.618));
               		   double fib_200_0 = Trade.NormalizePrice(lowestP + (fib_range*2.000));
               		   double fib_161_8 = Trade.NormalizePrice(lowestP + (fib_range*1.618));
               		   //printf("buy_fib_161_8");
               		   //printf(fib_161_8);
               		   double fib_080_0 = Trade.NormalizePrice(lowestP + (fib_range*0.800));
               		   double fib_061_8 = Trade.NormalizePrice(lowestP + (fib_range*0.618));
               		   double fib_050_0 = Trade.NormalizePrice(lowestP + (fib_range*0.500));
               		   double fib_038_2 = Trade.NormalizePrice(lowestP + (fib_range*0.382));
               		   double fib_023_6 = Trade.NormalizePrice(lowestP + (fib_range*0.236));
               		   
               		   //Make them dynamic
               		   //double profitFibLevel = 0.0;
               		   if(UseFibProfitLevel) profitFibLevel = fib_200_0;
               		   //double lossFibLevel = 0.0;
               		   if(AutoStopLossSet) {lossFibLevel = fib_050_0;}
               		   stopLossMM = MathAbs(fib_050_0 - SymbolInfoDouble(_Symbol,SYMBOL_ASK)) / point;//can change it to fib_061_8
               		   
               		   //profitFibLevel = fib_161_8;
               		   //lossFibLevel = fib_023_6;
               		   
               		   //Determine BE
               		   double be_range = MathAbs(fib_161_8 - SymbolInfoDouble(_Symbol,SYMBOL_ASK));
               		   if(BreakEvenProfit_ == 0 && be_range > 0){
               		      //double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
               		      //double StopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);//points
               		      BreakEvenProfit = be_range/point;//converting it to points
               		      LockProfit = ((be_range * (LockProfitPercentage/100)) /point) + StopLevel;
               		      printf("Break Even When points are =>"+BreakEvenProfit+" ,Points to lock =>"+ LockProfit+ " ::StopLevel => "+StopLevel);
               		      
               		   }else BreakEvenProfit = BreakEvenProfit_;
               		   //Determine/set lots
		                  SetLotSize(stopLossMM);
               		   string msg = " => [BUY Price: "+SymbolInfoDouble(_Symbol,SYMBOL_ASK)+"] \n"+
               			             "[LOT: "+tradeSize+"] \n"+
               			             "[SL-1:"+fib_050_0+"] \n"+
               			             "[SL-2:"+fib_061_8+"] \n"+
               			             "[TP-1:"+fib_161_8+"] \n"+
               			             "[TP-2:"+fib_200_0+"] \n"+
               			             " *"+EA_Version+"*";
               			 
               			 Price.SendAlert("BUY", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
		                   printf(msg);
		                  //--------fibs
		            }
		            ActivateSys3FinalSignal = "BUY";
		           
               	  
		   }else if(BCVolumeAreaSignalMain =="SELL" && BCVolumeAreaSignal == "SELL"){
		            if(ActivateSys3FinalSignal == "BUY"){
		                  sellPlaced = false;
                     	//Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
		                  lastSellSignalTime = getCandleTime(candleTimes,lastCandleTime,0);
		                  //--------fibs
		                  //for buys get the lowest price  betwwen previous sell, set it to selltrailP
		                  //+ get  number of candles between current signal and last sell
		                  int n_candles = 0;
		                  n_candles =Bars(_Symbol,PERIOD_CURRENT,lastSellSignalTime,lastBuySignalTime);
		                  //+ get the lowest in the series
		                  
		                  if(n_candles <= 0 || lastBuySignalTime == "1970.01.01 00:00:00" || lastSellSignalTime == "1970.01.01 00:00:00" || lastSellSignalTime == NULL || lastBuySignalTime == NULL){
		                     n_candles = 200;
		                  }
		                  
		                   printf("n_candles=>"+n_candles);
		                  printf("lastBuySignalTime=>"+lastBuySignalTime);
		                  printf("lastBuySignalTime=>"+lastSellSignalTime);
		                  double highestP = Price.HighestHigh(_Symbol,PERIOD_CURRENT,n_candles,0);
		          
		                  //--Getting Fib Levels
		                  double fib_range = Price.GetFibLevels(0, highestP ,  0, 0, "SELL");
		                  
		                  double fib_261_8 = Trade.NormalizePrice(highestP - (fib_range*2.618));
               		   double fib_200_0 = Trade.NormalizePrice(highestP - (fib_range*2.000));
               		   double fib_161_8 = Trade.NormalizePrice(highestP - (fib_range*1.618));
               		   //printf("sell_fib_161_8");
               		   //printf(fib_161_8);
               		   double fib_080_0 = Trade.NormalizePrice(highestP - (fib_range*0.800));
               		   double fib_061_8 = Trade.NormalizePrice(highestP - (fib_range*0.618));
               		   double fib_050_0 = Trade.NormalizePrice(highestP - (fib_range*0.500));
               		   double fib_038_2 = Trade.NormalizePrice(highestP - (fib_range*0.382));
               		   double fib_023_6 = Trade.NormalizePrice(highestP - (fib_range*0.236));
               		   
               		   //Make them dynamic
               		   //double profitFibLevel = 0.0;
               		   if(UseFibProfitLevel) profitFibLevel = fib_200_0;
               		   //double lossFibLevel = 0.0;
               		   if(AutoStopLossSet) {lossFibLevel = fib_050_0;}
               		   stopLossMM = MathAbs(fib_050_0 - SymbolInfoDouble(_Symbol,SYMBOL_BID)) / point;//can change it to fib_061_8
               		   
               		   //Determine BE
               		   double be_range = MathAbs(fib_161_8 - SymbolInfoDouble(_Symbol,SYMBOL_BID));
               		   if(BreakEvenProfit_ == 0 && be_range > 0){
               		      //double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
               		      //double StopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
               		      BreakEvenProfit = be_range/point;//converting it to points
               		      LockProfit = ((be_range * (LockProfitPercentage/100)) /point) + StopLevel;
               		      printf("Break Even When points are =>"+BreakEvenProfit+" ,Points to lock =>"+ LockProfit+ " ::StopLevel => "+StopLevel);
               		      
               		   }else BreakEvenProfit = BreakEvenProfit_;
               		   
               		   //Determine/set lots
		                   SetLotSize(stopLossMM);
		                   
               		   string msg = " => [SELL Price:"+SymbolInfoDouble(_Symbol,SYMBOL_BID)+"] \n"+
   			             "[LOT : "+tradeSize+"] \n"+
   			             "[SL-1: "+fib_050_0+"] \n"+
   			             "[SL-2: "+fib_061_8+"] \n"+
   			             "[TP-1: "+fib_161_8+"] \n"+
   			             "[TP-2: "+fib_200_0+"] \n"+
   			             " *"+EA_Version+"*";
			             
            			  Price.SendAlert("SELL", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
            			  printf(msg);
		   
		                  
		                  
		            }
		            ActivateSys3FinalSignal = "SELL";
		              
		   }
		   
		}else if(ActivateSys4){ 
		sonicSL =  Trade.NormalizePrice(SonicStopMA[0]);
		double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
	   //Determine/set lots
	   if(AutoStopLossSet) {lossFibLevel = sonicSL;}//if AllowSonicStopLevel
	   stopLossMM = MathAbs(sonicSL - SymbolInfoDouble(_Symbol,SYMBOL_ASK)) / point;//can change it to fib_061_8
      SetLotSize(stopLossMM);
      
		if(SonicTrendSigBuy[SonicBarIndex] > 0 && SonicTrendSigBuy[SonicBarIndex] != EMPTY_VALUE){//SonicBarIndex = 0
      			//cross up
      			Print("Sonic Trend Signal Buy Appeared!");
      			//closePosition();
      			SonicTrendSignal="BUY";
      			CloseAllTrades("SELL");//need to check on this
      			buyPlaced = false; 
      		   
      			
      			 string msg = " => [BUY Price:"+SymbolInfoDouble(_Symbol,SYMBOL_BID)+"] \n"+
   			             "[LOT : "+tradeSize+"] \n"+
   			             "[SL-1: "+sonicSL+"] \n"+
   			             "[TP-1: --] \n"+
   			             " *"+EA_Version+"*";
      			Price.SendAlert("BUY", "\n "+msg+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
      			
      			
      		}
      if(SonicTrendSigSell[SonicBarIndex] > 0 && SonicTrendSigSell[SonicBarIndex] != EMPTY_VALUE){
      			//cross down
      			Print("Sonic Trend Signal Sell Appeared!");
      			//closePosition();
      			SonicTrendSignal="SELL";
      			CloseAllTrades("BUY");//need to check on this
      			sellPlaced = false;
      			string msg = " => [SELL Price:"+SymbolInfoDouble(_Symbol,SYMBOL_BID)+"] \n"+
   			             "[LOT : "+tradeSize+"] \n"+
   			             "[SL-1: "+sonicSL+"] \n"+
   			             "[TP-1: --] \n"+
   			             " *"+EA_Version+"*";
      			Price.SendAlert("SELL", "\n "+msg+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
      			 
      		}
		}
		
		 
	   //close by profits
	   CloseMiniProfitsLongs();
		//Check Daily Target
	   CheckDailyTarget();
	   // Break even
   	if(UseBreakEven == true && PositionType(_Symbol) != -1){
   	   Trail.BreakEven(_Symbol,BreakEvenProfit,LockProfit);
   	}
   	
   	
   	// Trailing stop
   	if(UseTrailingStop == true && PositionType(_Symbol) != -1)
   	{
   	   Trail.TrailingStop(_Symbol,TrailingStop,MinimumProfit,Step);
   	}
	   
	   
	   
	}
	//Check and remove closedFalls if crushes and booms are done
	/*if(
	   ((_Symbol == "Crash 1000 Index" || _Symbol == "Crash 500 Index") && ((CurTrend == "BUYING" && ActivateSys1)  || (CurTrendNonLag == "BUYING" && ActivateSys2))) ||
	   ((_Symbol == "Boom 1000 Index" || _Symbol == "Boom 500 Index") && ((CurTrend == "SELLING" && ActivateSys1) || (CurTrendNonLag == "SELLING" && ActivateSys2)))
	)
	{
	   closedFalls = false;
	   TradeOnEveryTickL = TradeOnEveryTick;
	}*/
	
	//Prepare for trading
	
	if(NewBar.CheckNewBar(_Symbol,_Period) && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades && !innerlocked){
	
	    if(((CurSignal=="BUY" && ActivateSys1) || (CurSignalNonLag =="BUY" && ActivateSys2) || (BCVolumeAreaSignalMain =="BUY" && ActivateSys3) || (SonicTrendSignal=="BUY") && ActivateSys4) && !buyPlaced ){
	     if(AllowedPriceGap > 0.0 && (AllowedPriceGap >= CurrentPriceGapRange) ){
	         if(UseBCVolumeAreaFilter && BCVolumeAreaSignal == "BUY"){
      	      if(FullAutoPilot)
      		      makePosition(orderBuy);
      		     else if(BuyOnly) 
      		      makePosition(orderBuy);
      		 }else if(!UseBCVolumeAreaFilter){
         		  if(FullAutoPilot)
         		      makePosition(orderBuy);
         		     else if(BuyOnly) 
         		      makePosition(orderBuy);
      		 }
   		      
		    }else if(AllowedPriceGap == 0.0){//just trade if gap not specified
   		    if(UseBCVolumeAreaFilter && BCVolumeAreaSignal == "BUY"){
      		     if(FullAutoPilot)
         		      makePosition(orderBuy);
         		     else if(BuyOnly) 
         		      makePosition(orderBuy);
         	}else if(!UseBCVolumeAreaFilter){
               	if(FullAutoPilot)
         		      makePosition(orderBuy);
         		     else if(BuyOnly) 
         		      makePosition(orderBuy);
             }
		    }
		 }
		 if(((CurSignal=="SELL" && ActivateSys1)  || (CurSignalNonLag =="SELL" && ActivateSys2) || (BCVolumeAreaSignalMain =="SELL" && ActivateSys3) || (SonicTrendSignal=="SELL") && ActivateSys4) && !sellPlaced){
   		 if(AllowedPriceGap > 0.0 && (AllowedPriceGap >= CurrentPriceGapRange) ){
   		   if(UseBCVolumeAreaFilter && BCVolumeAreaSignal == "SELL"){
         	    if(FullAutoPilot)
         		      makePosition(orderSell);
         		     else if(SellOnly) 
         		      makePosition(orderSell);
      		    }else if(!UseBCVolumeAreaFilter){
         		    if(FullAutoPilot)
            		      makePosition(orderSell);
            		     else if(SellOnly) 
            		      makePosition(orderSell);
      		    }
   		     }else if(AllowedPriceGap == 0.0){//just trade if gap not specified
      		     if(UseBCVolumeAreaFilter && BCVolumeAreaSignal == "SELL"){
         		     if(FullAutoPilot)
            		      makePosition(orderSell);
            		     else if(SellOnly) 
            		      makePosition(orderBuy);
            		 }else if(!UseBCVolumeAreaFilter){
            		  if(FullAutoPilot)
            		      makePosition(orderSell);
            		     else if(SellOnly) 
            		      makePosition(orderBuy);
            		 }
   		    }
		 }
	}/*
	else if(TradeOnEveryTickL && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades && !innerlocked){
   	    if(((CurSignal=="BUY" && ActivateSys1) || (CurSignalNonLag =="BUY" && ActivateSys2)) && !buyPlaced){
   	      if(FullAutoPilot)
   		      makePosition(orderBuy);
   		   else if(BuyOnly) 
   		      makePosition(orderBuy);
   		 }
   		 if(((CurSignal=="SELL" && ActivateSys1)  || (CurSignalNonLag =="SELL" && ActivateSys2)) && !sellPlaced){
      		 if(FullAutoPilot)
      		   makePosition(orderSell);
      		 else if(SellOnly) 
      		   makePosition(orderSell);
   		 }
	}
	*/
	
   	
//### By Cash ###########
double TotalProfit = TotalProfit();
	if(UseTakeProfitCash){
	
	//profits
   	if(TotalProfit >=takeProfitCash && (takeProfitCash != 0.0) && !FibProfitUsed){//check if orders have tp set , it the best way
         	   if(!AllSymbols){
                  TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
                }
                else{
                    TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );      
                }
        }
  //losses
     if((curBalProfit < -(lossToStopDayTrading) || TotalProfit < -(lossToStopDayTrading)) && (lossToStopDayTrading != 0.0)){
   	   if(!AllSymbols){
            TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
            PlaceTrades= false;
            //send notification
            //Stop auto trading
          }
          else{
              CloseAllTrades();      
          }
   	}
  
   }
   //### By Percentage  ###########
   else if(UseTakeProfitPercentage){
      //profits         	
   	if(TotalProfit >= ((takeProfitPercentage/100) * onStartEquity) && (takeProfitPercentage != 0.0) && !FibProfitUsed){
   	   if(!AllSymbols){
            TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
          }
          else{
              CloseAllTrades();      
          }
   	}
   	//losses
     if((curBalProfit < -((PercentagelossToStopDayTrading/100) * onStartEquity)) ||
         (TotalProfit < -((PercentagelossToStopDayTrading/100) * onStartEquity)) &&
       (PercentagelossToStopDayTrading != 0.0)){
   	   if(!AllSymbols){
            TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
            PlaceTrades= false;
            //send notification
            //Stop auto trading
          }
          else{
              CloseAllTrades();      
          }
   	}
   }
	
	//*****************
	
}

void CloseMiniProfitsLongs(){
   //Taking Profits
   	if(
   	   ((_Symbol == "Crash 1000 Index" || _Symbol == "Crash 500 Index" || _Symbol == "Crash 300 Index") && ((CurTrend == "SELLING" && ActivateSys1) || (CurTrendNonLag == "SELLING" && ActivateSys2))) ||
   	   ((_Symbol == "Boom 1000 Index" || _Symbol == "Boom 500 Index" || _Symbol == "Boom 300 Index") && ((CurTrend == "BUYING" && ActivateSys1) || (CurTrendNonLag == "BUYING" && ActivateSys2)))
   	){ 
   	   //TradeOnEveryTickL = false;
   	   double TotalProfit = TotalProfit();
   	   if(UseTakeProfitCash){
      	   if(TotalProfit >= takeProfitCashLongs && (takeProfitCashLongs != 0.0) && !FibProfitUsed){
       
            	  // if(!AllSymbols){    	
                     TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
                 //  }
                  // else{
                     //  CloseAllTrades();      
                 //  }
                   //if(TradeLongsOnce)closedFalls = true;
            	}
   	   
   	   }else if(UseTakeProfitPercentage){
         	if(TotalProfit >= ((takeProfitPercentageLongs/100) * onStartEquity) && (takeProfitPercentageLongs != 0.0) && !FibProfitUsed){
       
            	  // if(!AllSymbols){    	
                     TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
                 //  }
                   //else{
                     //  CloseAllTrades();      
                 //  }
                   //if(TradeLongsOnce)closedFalls = true;
            	}
        }
        
        //##################
   }
	 
}

bool CheckDailyTarget(){
   double curTodayprofit = AccountInfoDouble(ACCOUNT_BALANCE) - onStartEquity;
   double expTodayprofit = (DailyProfitPercentage/100)*onStartEquity;

   if((curTodayprofit >= expTodayprofit && UseTakeProfitPercentage) || (curTodayprofit >= DailyProfitCash && UseTakeProfitCash))//target reached
   {
      innerlocked = true;
      PlaceTrades= false;
      //send notification//target archieved
      return true;  
   }
   else{
      return false;
   }
}

bool makePosition(orderType type){

	   
	   if(stopLossMM == 0.0 && StopLoss > 0.0){
	      stopLossMM = StopLoss;//points
	   }
	   // Money management
		if(UseMoneyManagement == true) { tradeSize = MoneyManagement(_Symbol,volume,RiskPercent,stopLossMM);}
		else {tradeSize = VerifyVolume(_Symbol,volume);}
		tradeSize = volume;
		
   int tradeCount = MaximumTradeCount;
   while(tradeCount > 0){
      //logic to buy or sell once in Crushing or booming market
     /* if((
   	   ((_Symbol == "Crash 1000 Index" || _Symbol == "Crash 500 Index") && ((CurTrend == "SELLING" && ActivateSys1) || (CurTrendNonLag == "SELLING" && ActivateSys2))) ||
   	   ((_Symbol == "Boom 1000 Index" || _Symbol == "Boom 500 Index") && ((CurTrend == "BUYING" && ActivateSys1) || (CurTrendNonLag == "BUYING" && ActivateSys2)))
   	   ) && closedFalls
   	){
   	   return false;
   	}*/
      //--ends here
   	ZeroMemory(request);
   	request.symbol=_Symbol;
   	request.volume=tradeSize;
   	request.action=TRADE_ACTION_DEAL;
   	request.type_filling=ORDER_FILLING_FOK;
   	request.magic = MagicNumber;
   	request.comment = EA_Version+" TF:"+Price.GetTimeFrame();
   	double price=0;
   	//setting stop losses
   	/*if(
   	   ((_Symbol == "Crash 1000 Index" || _Symbol == "Crash 500 Index") && ((CurTrend == "BUYING" && ActivateSys1)  || (CurTrendNonLag == "BUYING" && ActivateSys2))) ||
   	   ((_Symbol == "Boom 1000 Index" || _Symbol == "Boom 500 Index") && ((CurTrend == "SELLING" && ActivateSys1) || (CurTrendNonLag == "SELLING" && ActivateSys2)))
   	)
   	{
   	   // Update prices
   	   Price.Update(_Symbol,_Period);
   	   request.sl=NormalizeDouble(Price.Open(1),_Digits);
   	}*/
   	//setting stop levels
   	if(UseFibProfitLevel) {
   	   request.tp = NormalizeDouble(profitFibLevel,_Digits);
   	   FibProfitUsed = true; 
   	}else{
   	   FibProfitUsed = false;
   	}
      if(AutoStopLossSet) request.sl = NormalizeDouble(lossFibLevel, _Digits);
      
      
   
   	if(type==orderBuy){
   	   //Close All Sells
   	   CloseAllTrades("SELL"); 
   		//Buy
   		request.type=ORDER_TYPE_BUY;
   		price=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   		if(stopLoss > 0.0) request.sl=NormalizeDouble(price-stopLoss,_Digits);
   		if(takeProfit > 0.0)request.tp=NormalizeDouble(price+takeProfit,_Digits);
   		
   	}else if(type==orderSell){
   	   //Close All Buys
   	   CloseAllTrades("BUY"); 
   		//Sell
   		request.type=ORDER_TYPE_SELL;
   		price=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   		if(stopLoss > 0.0)request.sl=NormalizeDouble(price+stopLoss,_Digits);
   		if(takeProfit > 0.0)request.tp=NormalizeDouble(price-takeProfit,_Digits);
   
   	}
   	request.deviation=10;
   	request.price=price;
   
   
   	if(OrderCheck(request,checkResult)){
   		Print("Checked!");
   		lastError = "Order Placed Successfully";
   	}else{
   		 //Print("Not Checked! ERROR :"+IntegerToString(checkResult.retcode));
   		 Print(__FUNCTION__,"():Not Checked! ERROR : ",ResultRetcodeDescription(checkResult.retcode));
   		 lastError = "Order Not Checked! ERROR : "+ResultRetcodeDescription(checkResult.retcode);
   		 break;
   		 //return false;
   	}
   
   	if(OrderSend(request,result)){
   		Print("order sent successfully:)");
   	}else{
   		Print("order not sent!");
   		 break;
   		//return false;
   	}
   
   	if(result.retcode==TRADE_RETCODE_DONE || result.retcode==TRADE_RETCODE_PLACED){
   		Print("Trade Placed!");
   		if(type==orderBuy){
   		   buyPlaced = true;
   		   sellPlaced = false;
   		}else if(type==orderSell){
   		   sellPlaced = true;
   		   buyPlaced = false;
   		}
   		tradeCount = tradeCount - 1;
   		//return true;
   	}/*else{
   		return false;
   	}*/
	}
//--check if any has been placed.
   if(buyPlaced || sellPlaced){
      TakeChartScreenShot("NEW ORDER");
      return true;
   }else{
      TakeChartScreenShot("NEW ORDER FAILED");
      return false;
   }
}

bool checkNewCandle(datetime &candles[],datetime &last){
	bool newCandle=false;

	CopyTime(_Symbol,_Period,0,3,candles);

	if(last!=0){
		if(candles[0]>last){
			newCandle=true;
			last=candles[0];
		}
	}else{
		last=candles[0];
	}

	return newCandle;
}

bool checkNewCandle2(datetime &candles[],datetime &last){
	bool newCandle=false;

	CopyTime(_Symbol,_Period,0,3,candles);

	if(last!=0){
		if(candles[0]>last){
			newCandle=true;
			last=candles[0];
		}
	}else{
		last=candles[0];
	}

	return newCandle;
}

datetime getCandleTime(datetime &candles[],datetime &last, int seq){
	CopyTime(_Symbol,_Period,0,3,candles);
	last = candles[seq];
	return last;
}

bool closePosition(){
	TradeX.PositionClose(_Symbol ,Slippage );
	return true;
}

void CloseAllTrades()
  {
//----   
   for(uint count=0; count<=RTOTAL && !IsStopped(); count++)
     {
      //---- закрываем все открытые позиции по текущему символу
      int total=PositionsTotal();
      if(!total) return; // все позиции закрыты
      for(int pos=total-1; pos>=0; pos--)
        {
         ulong ticket=ulong(PositionGetTicket(pos));
         if(!PositionSelectByTicket(ticket)) continue;
          string symbol=PositionGetSymbol(pos);
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
           {
            bool BUY_Close=true;
            BuyPositionClose(BUY_Close,symbol,Deviation_);
           }
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
           {
            bool SELL_Close=true;
            SellPositionClose(SELL_Close,symbol,Deviation_);
           }
        }
      if(!PositionsTotal()) break;
      Sleep(SLEEPTIME*1000);
     }
//----
  }
  
  void CloseAllTrades(string OrderType)
  {
//----   
   for(uint count=0; count<=RTOTAL && !IsStopped(); count++)
     {
      //---- закрываем все открытые позиции по текущему символу
      int total=PositionsTotal();
      if(!total) return; // все позиции закрыты
      for(int pos=total-1; pos>=0; pos--)
        {
         ulong ticket=ulong(PositionGetTicket(pos));
         if(!PositionSelectByTicket(ticket)) continue;
          string symbol=PositionGetSymbol(pos);
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && OrderType == "BUY")
           {
            bool BUY_Close=true;
            BuyPositionClose(BUY_Close,symbol,Deviation_);
           }
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && OrderType == "SELL")
           {
            bool SELL_Close=true;
            SellPositionClose(SELL_Close,symbol,Deviation_);
           }
        }
       
      if(!PositionsTotal()) break;
      Sleep(SLEEPTIME*1000);
     }
     //
//----
  }
//+------------------------------------------------------------------+
//| Закрываем длинную позицию                                        |
//+------------------------------------------------------------------+
bool BuyPositionClose
(
bool &Signal,         // флаг разрешения на сделку
const string symbol,  // торговая пара сделки
uint deviation        // слиппаж
)
  {
//----
   if(!Signal) return(true);

//---- Объявление структур торгового запроса и результата торгового запроса
   MqlTradeRequest request;
   MqlTradeResult result;
//---- Объявление структуры результата проверки торгового запроса 
   MqlTradeCheckResult check;

//---- обнуление структур
   ZeroMemory(request);
   ZeroMemory(result);
   ZeroMemory(check);

//---- Проверка на наличие открытой BUY позиции
   if(PositionSelect(symbol))
     {
      if(PositionGetInteger(POSITION_TYPE)!=POSITION_TYPE_BUY) return(false);
     }
   else return(false);

   double MaxLot,tradeSize,Bid;
//---- получение данных для расчёта    
   if(!PositionGetDouble(POSITION_VOLUME,tradeSize)) return(true);
   if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX,MaxLot)) return(true);
   if(!SymbolInfoDouble(symbol,SYMBOL_BID,Bid)) return(true);

//---- проверка лота на максимальное допустимое значение       
   if(tradeSize>MaxLot) tradeSize=MaxLot;

//---- Инициализация структуры торгового запроса MqlTradeRequest для закрывания BUY позиции
   request.type   = ORDER_TYPE_SELL;
   request.price  = Bid;
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = tradeSize;
   request.sl = 0.0;
   request.tp = 0.0;
   request.deviation=deviation;
   request.comment = "EA - Closed#2";
// request.type_filling=ORDER_FILLING_FOK;
   request.position=PositionGetInteger(POSITION_TICKET); 

//---- Проверка торгового запроса на корректность
   if(!OrderCheck(request,check))
     {
      Print(__FUNCTION__,"(): Invalid data for trade request structure!");
      Print(__FUNCTION__,"(): OrderCheck(): ",ResultRetcodeDescription(check.retcode));
      return(false);
     }
//----     
   string comment="";
   StringConcatenate(comment,"<<< ============ ",__FUNCTION__,"(): Закрываем Buy позицию по ",symbol," ============ >>>");
   Print(comment);

//---- Отправка приказа на закрывание позиции на торговый сервер
   if(!OrderSend(request,result) || result.retcode!=TRADE_RETCODE_DONE)
     {
      Print(__FUNCTION__,"(): Unable to close position!");
      Print(__FUNCTION__,"(): OrderSend(): ",ResultRetcodeDescription(result.retcode));
      return(false);
     }
   else
   if(result.retcode==TRADE_RETCODE_DONE)
     {
      Signal=false;
      comment="";
      StringConcatenate(comment,"<<< ============ ",__FUNCTION__,"(): Buy position on ",symbol," closed ============ >>>");
      Print(comment);
      PlaySound("ok.wav");
      //take a shot
       TakeChartScreenShot("ORDER CLOSE"); 
     }
   else
     {
      Print(__FUNCTION__,"(): Unable to close position!");
      Print(__FUNCTION__,"(): OrderSend(): ",ResultRetcodeDescription(result.retcode));
      return(false);
     }
//----
   return(true);
  }
//+------------------------------------------------------------------+
//| Закрываем короткую позицию                                       |
//+------------------------------------------------------------------+
bool SellPositionClose
(
bool &Signal,         // флаг разрешения на сделку
const string symbol,  // торговая пара сделки
uint deviation        // слиппаж
)
  {
//----
   if(!Signal) return(true);

//---- Объявление структур торгового запроса и результата торгового запроса
   MqlTradeRequest request;
   MqlTradeResult result;
//---- Объявление структуры результата проверки торгового запроса 
   MqlTradeCheckResult check;

//---- обнуление структур
   ZeroMemory(request);
   ZeroMemory(result);
   ZeroMemory(check);

//---- Проверка на наличие открытой SELL позиции
   if(PositionSelect(symbol))
     {
      if(PositionGetInteger(POSITION_TYPE)!=POSITION_TYPE_SELL)return(false);
     }
   else return(false);

   double MaxLot,tradeSize,Ask;
//---- получение данных для расчёта    
   if(!PositionGetDouble(POSITION_VOLUME,tradeSize)) return(true);
   if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX,MaxLot)) return(true);
   if(!SymbolInfoDouble(symbol,SYMBOL_ASK,Ask)) return(true);

//---- проверка лота на максимальное допустимое значение       
   if(tradeSize>MaxLot) tradeSize=MaxLot;

//---- Инициализация структуры торгового запроса MqlTradeRequest для закрывания SELL позиции
   request.type   = ORDER_TYPE_BUY;
   request.price  = Ask;
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = tradeSize;
   request.comment = "EA - Closed#2";
   request.sl = 0.0;
   request.tp = 0.0;
   request.deviation=deviation;
// request.type_filling=ORDER_FILLING_FOK;
   request.position=PositionGetInteger(POSITION_TICKET); 

//---- Проверка торгового запроса на корректность
   if(!OrderCheck(request,check))
     {
      Print(__FUNCTION__,"(): Invalid data for trade request structure!");
      Print(__FUNCTION__,"(): OrderCheck(): ",ResultRetcodeDescription(check.retcode));
      return(false);
     }
//----    
   string comment="";
   StringConcatenate(comment,"<<< ============ ",__FUNCTION__,"(): Close the Sell position by ",symbol," ============ >>>");
   Print(comment);

//---- Отправка приказа на закрывание позиции на торговый сервер
   if(!OrderSend(request,result) || result.retcode!=TRADE_RETCODE_DONE)
     {
      Print(__FUNCTION__,"(): Unable to close position!");
      Print(__FUNCTION__,"(): OrderSend(): ",ResultRetcodeDescription(result.retcode));
      return(false);
     }
   else
   if(result.retcode==TRADE_RETCODE_DONE)
     {
      Signal=false;
      comment="";
      StringConcatenate(comment,"<<< ============ ",__FUNCTION__,"(): Sell ​​position on ",symbol," closed ============ >>>");
      Print(comment);
      PlaySound("ok.wav");
      //take a shot
       TakeChartScreenShot("ORDER CLOSE"); 
     }
   else
     {
      Print(__FUNCTION__,"(): Unable to close position!");
      Print(__FUNCTION__,"(): OrderSend(): ",ResultRetcodeDescription(result.retcode));
      return(false);
     }
//----
   return(true);
  }
  /*
  double ProfitCheck()
{
   double profit=0;
   int total  = OrdersTotal();
      for (int cnt = total-1 ; cnt >=0 ; cnt--)
      {
         OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES);
         if(AllSymbols)
            profit+=OrderProfit();
         else if(OrderSymbol()==Symbol())
            profit+=OrderProfit();
      }
   return(profit);        
}*/

double TotalProfit()
  {
   double pft=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0)
        {
          if(!AllSymbols){
            if(PositionGetInteger(POSITION_MAGIC)== MagicNumber && PositionGetString(POSITION_SYMBOL)==Symbol())
              {
               pft+=PositionGetDouble(POSITION_PROFIT);
              }
             }
             else{
                  pft+=PositionGetDouble(POSITION_PROFIT);
             }
        }
     }
     
   return(pft);
  }

//+------------------------------------------------------------------+
//| возврат стрингового результата торговой операции по его коду     |
//+------------------------------------------------------------------+
string ResultRetcodeDescription(int retcode)
  {
   string str;
//----
   switch(retcode)
     {
      case TRADE_RETCODE_REQUOTE: str="1-TRADE_RETCODE_REQUOTE"; break;
      case TRADE_RETCODE_REJECT: str="2-TRADE_RETCODE_REJECT"; break;
      case TRADE_RETCODE_CANCEL: str="3-TRADE_RETCODE_CANCEL"; break;
      case TRADE_RETCODE_PLACED: str="4-TRADE_RETCODE_PLACED"; break;
      case TRADE_RETCODE_DONE: str="5-TRADE_RETCODE_DONE"; break;
      case TRADE_RETCODE_DONE_PARTIAL: str="TRADE_RETCODE_DONE_PARTIAL"; break;
      case TRADE_RETCODE_ERROR: str="6-TRADE_RETCODE_ERROR"; break;
      case TRADE_RETCODE_TIMEOUT: str="7-TRADE_RETCODE_TIMEOUT";break;
      case TRADE_RETCODE_INVALID: str="8-TRADE_RETCODE_INVALID"; break;
      case TRADE_RETCODE_INVALID_VOLUME: str="9-TRADE_RETCODE_INVALID_VOLUME"; break;
      case TRADE_RETCODE_INVALID_PRICE: str="10-TRADE_RETCODE_INVALID_PRICE"; break;
      case TRADE_RETCODE_INVALID_STOPS: str="11-TRADE_RETCODE_INVALID_STOPS"; break;
      case TRADE_RETCODE_TRADE_DISABLED: str="12-TRADE_RETCODE_TRADE_DISABLED"; break;
      case TRADE_RETCODE_MARKET_CLOSED: str="13-TRADE_RETCODE_MARKET_CLOSED"; break;
      case TRADE_RETCODE_NO_MONEY: str="14-TRADE_RETCODE_NO_MONEY"; break;
      case TRADE_RETCODE_PRICE_CHANGED: str="15-Цены изменились"; break;
      case TRADE_RETCODE_PRICE_OFF: str="16-TRADE_RETCODE_PRICE_CHANGED"; break;
      case TRADE_RETCODE_INVALID_EXPIRATION: str="17-TRADE_RETCODE_INVALID_EXPIRATION"; break;
      case TRADE_RETCODE_ORDER_CHANGED: str="18-TRADE_RETCODE_ORDER_CHANGED"; break;
      case TRADE_RETCODE_TOO_MANY_REQUESTS: str="19-TRADE_RETCODE_TOO_MANY_REQUESTS"; break;
      case TRADE_RETCODE_NO_CHANGES: str="20-TRADE_RETCODE_NO_CHANGES"; break;
      case TRADE_RETCODE_SERVER_DISABLES_AT: str="21-TRADE_RETCODE_SERVER_DISABLES_AT"; break;
      case TRADE_RETCODE_CLIENT_DISABLES_AT: str="22-TRADE_RETCODE_CLIENT_DISABLES_AT"; break;
      case TRADE_RETCODE_LOCKED: str="23-TRADE_RETCODE_LOCKED"; break;
      case TRADE_RETCODE_FROZEN: str="24-TRADE_RETCODE_FROZEN"; break;
      case TRADE_RETCODE_INVALID_FILL: str="25-TRADE_RETCODE_INVALID_FILL "; break;
      case TRADE_RETCODE_CONNECTION: str="26-TRADE_RETCODE_CONNECTION"; break;
      case TRADE_RETCODE_ONLY_REAL: str="27-TRADE_RETCODE_ONLY_REAL"; break;
      case TRADE_RETCODE_LIMIT_ORDERS: str="28-TRADE_RETCODE_LIMIT_ORDERS"; break;
      case TRADE_RETCODE_LIMIT_VOLUME: str="29-TRADE_RETCODE_LIMIT_VOLUME"; break;
      case TRADE_RETCODE_INVALID_ORDER: str="30-TRADE_RETCODE_INVALID_ORDER"; break;
      case TRADE_RETCODE_POSITION_CLOSED: str="31-TRADE_RETCODE_POSITION_CLOSED"; break;
      default: str="00-unknown result";
     }
//----
   return(str);
  }
  
  int CalculatePriceGap(double firstPrice){
//--- obtain spread from the symbol properties
   string comm = "";
   /*bool spreadfloat=SymbolInfoInteger(Symbol(),SYMBOL_SPREAD_FLOAT);
   string comm=StringFormat("Spread %s = %I64d points\r\n",
                            spreadfloat?"floating":"fixed",
                            SymbolInfoInteger(Symbol(),SYMBOL_SPREAD));*/
//--- now let's calculate the spread by ourselves
   double ask=SymbolInfoDouble(Symbol(),SYMBOL_ASK);//base on current signal to know uy / sell
   //double bid=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   //double spread=ask-bid;
   double gap = MathAbs(firstPrice - ask);
   //int spread_points=(int)MathRound(gap/SymbolInfoDouble(Symbol(),SYMBOL_POINT));
   int spread_points=(int)MathRound(gap);
   //comm=comm+"Calculated spread = "+(string)spread_points+" points";
   //Comment(comm);
   return spread_points;
}
/*long PositionType(string pSymbol = NULL)
{
	if(pSymbol == NULL) pSymbol = _Symbol;
	bool select = PositionSelect(pSymbol);
	if(select == true) return(PositionGetInteger(POSITION_TYPE));
	else return(WRONG_VALUE);
}*/

//Take Screen Shoot
void TakeChartScreenShot(string description_){
//https://www.mql5.com/en/forum/328971
//https://www.mql5.com/en/docs/chart_operations/chartscreenshot
   MqlDateTime today;
   TimeCurrent(today);
   //Print( "Today is " + DayOfWeek(today.day_of_week) );
   string cur_T = TimeCurrent();
   string name = "shots\\MyJournel\\"+DayOfWeek(today.day_of_week)+"\\"+Symbol()+" - "+Price.GetTimeFrame()+"-"+ cur_T +"-"+description_+".gif";
   
   //Scroll to current
   //bool cur_scroll_set = 
   ChartAutoscrollSet(true,0);
   //WindowScreenShot(,640,640);
  if(ChartScreenShot(0,name,640,640,ALIGN_LEFT))
               printf("We've saved the screenshot ",name);
  }
string DayOfWeek(int dow){
   string day[] = {"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"};
   return day[dow];
}

//Set lot size
void SetLotSize(double stopLossMM_){
  // Money management
		if(UseMoneyManagement == true) { tradeSize = MoneyManagement(_Symbol,volume,RiskPercent,stopLossMM_);}
		else {tradeSize = VerifyVolume(_Symbol,volume);}
		tradeSize = volume;
  }
  
//Auto Scroll
//+------------------------------------------------------------------+
//| Checks if automatic scrolling of a chart to the right            |
//| on new ticks arrival is enabled                                  |
//+------------------------------------------------------------------+
bool ChartAutoscrollGet(bool &result,const long chart_ID=0)
  {
//--- prepare the variable to get the property value
   long value;
//--- reset the error value
   ResetLastError();
//--- receive the property value
   if(!ChartGetInteger(chart_ID,CHART_AUTOSCROLL,0,value))
     {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
      return(false);
     }
//--- store the value of the chart property in memory
   result=value;
//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+
//| Enables/disables automatic scrolling of a chart to the right     |
//| on new ticks arrival                                             |
//+------------------------------------------------------------------+
bool ChartAutoscrollSet(const bool value,const long chart_ID=0)
  {
//--- reset the error value
   ResetLastError();
//--- set property value
   if(!ChartSetInteger(chart_ID,CHART_AUTOSCROLL,0,value))
     {
      //--- display the error message in Experts journal
      Print(__FUNCTION__+", Error Code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }

 
//+------------------------------------------------------------------+

   

