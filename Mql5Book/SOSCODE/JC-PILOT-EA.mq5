//+------------------------------------------------------------------+
//|       Corrected Moving Average (CMA) & Corrected Trend Step (CTS)|
//|                                       Trading View/Kiyingi Denis |
//|                                 http://www.expertadvisorbook.com |
//|                                http://www.buero-uhl.de/papers.htm|
//+------------------------------------------------------------------+

#property copyright "Jordan Capital Inc."
#property link      "https://www.buymeacoffee.com/jordancapitalfx"
#property version   "2024.05.21-19:30"
#property description "CMA & CTS"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/
//To Dos ********************

// Trade
#include <Mql5Book\TradeHedge.mqh>
CTradeHedge Trade;
CPositions Positions;

// Price
#include <Mql5Book\Price.mqh>
CBars Bar;

#include <Trade\XTrade.mqh>
//#include <Mql5Book\XTrade.mqh>
CTrade TradeX;

// Money management
#include <Mql5Book\MoneyManagement.mqh>

// Trailing stops
#include <Mql5Book\TrailingStops.mqh>
CTrailing Trail;

// Price
#include <Mql5Book\Price.mqh>
CBars Price;

// Timer
#include <Mql5Book\Timer.mqh>
CTimer Timer;
CNewBar NewBar;

// Indicators 
#include <Mql5Book\Indicators.mqh>
//#include <WinUser32.mqh>

//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
input bool alertsOnly = false;
input bool PlaceTradesInPut = false;
input ulong MyMagicNumber = 0;
input bool TradeOnNewBar = true;

sinput string MM; 	// Money Management
input bool UseMoneyManagement = false;
input double RiskPercent = 2;
input double FixedVolume = 0.001;
input int ConsecutiveLossesAllowed_ = 5;
input int OnLossesResetCount_ = 2;
input bool ConsecutiveLossesOnlyDaily = false;
input ulong Slippage = 3;
input double AllowedPriceGap = 0.0;	

sinput string SL; 	// Stop Loss & Take Profit
input bool AutoSetLoss_ = false;
input bool AutoSetProfit_ = false;
input double AutoProfitRatio = 3.0;
input int StopLoss_ = 0;
input int TakeProfit_ = 0;

sinput string Orders;
input int MaximumTradeCount = 2;
input int TradeBasketsPerTrend = 1;
input int TotalAccMaximumTradeCount = 6; 	
input bool SingleOrderType = false;
input bool doSells_ = true;
input bool doBuys_ = true;
input bool TradeOnEveryTick = false;
input bool DistributeTrades = false;
input int DistributeTradesCount = 1;

sinput string BE;		// Break Even
input bool UseBreakEven = true;
input int BreakEvenProfit_ = 0;
input int LockProfit_ = 0;
input double LockProfitPercentage = 2;
input double LockProfitWhenPercentageIs = 0.5;
input bool useSteadyProgressRecover = true;
input bool StopLossOverideOnRecover = true;


sinput string TS;		// Trailing Stop
input bool UseTrailingStop = false;
input int TrailingStop = 0;
input int MinimumProfit = 0;
input int Step = 0; 

sinput string _MeasuresOn_;
input bool AllSymbols = false;

sinput string _CashMeasures_;
input bool UseTakeProfitCash_=false;
input double takeProfitCash_=5.0;
input double takeLossCash_=0.0;
input double DailyProfitCash_=10.0;
input double lossToStopDayTrading_=20.0;


sinput string PercentageMeasures;
input bool UseTakeProfitPercentage_=true;
input double takeProfitPercentage=5.0;
input double takeLossPercentage=0.0;
input double DailyProfitPercentage=10;
input double PercentagelossToStopDayTrading = 20;

sinput string TradeMethod;	
input bool useTRADEVIEW =true;

sinput string __fibs__;	
input bool useOptimizedFibo_ = false;
input bool UseFibStopLossLevel_ = true;
input bool UseFibProfitLevel_ = true;
input bool StaticFibo = false;
input double _StopLoss_Fib = 38.2;
input double _BreakEven_Fib = 200.0;
input double _TakeProfit_Fib = 200.0;

sinput string ALERTS;		
input bool   alertsOnCurrent = false;
input bool   alertsOnlyTrendChg = true;
input bool   alertsMessage   = false;
input bool   alertsOnPhone   = true;
input bool   alertsEmail     = false;
input bool   alertsSound     = false;
input bool   alertsTelegram  = false;
input bool   alertsOptimised  = true;
input bool   turnlogOn  = true;
input string     APIkey      = "1819898948:AAFRCYc45DMt_hTjwRtUuk58iRIvc1bRcIs";
input string     Channel_ID  = "-1001860762374";

sinput string TI; 	// Timer
input bool UseCustomTimer = true;
input int UPSTREAM_CALL_INTVAL_SECONDS_ = 30;
input string ENDPOINT_URL = "DEFAULT";
input string licenceKey = "hellojc";
input bool UseCustomAsset = false;
input string CustomAsset_ = "EURUSD";





//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
//datetime compilation_date_time=__DATETIME__;    // Compilation date and time
string EA_Version = "#JC.PILOT.V1";
//#define ENDPOINT_URL_DEFAULT "http://127.0.0.1:9090/api/check-orders"
#define ENDPOINT_URL_DEFAULT "http://jc-engine.ec2-3-239-240-229.compute-1.amazonaws.com.sslip.io/api/check-orders"
ulong glBuyTicket, glSellTicket;
static datetime lastCallTime = 0;

int UPSTREAM_CALL_INTVAL_SECONDS = UPSTREAM_CALL_INTVAL_SECONDS_;
static string CustomAsset = CustomAsset_;
static string UpstreamSignalOrderType = "";
string strategyName = "UHLMA";
static int UpStreamTimeFrame =  Period();
static string TradeComment = EA_Version;
datetime lastSigCandleTime;



enum Signal_Actual
{
	SIGNAL_BUY,
	SIGNAL_SELL,
	SIGNAL_NONE,
};

Signal_Actual glSignal;

datetime candleTimes[],lastCandleTime;
int MagicNumber=0;
string Current_Symbol= "";
bool doSells = doSells_;
bool doBuys = doBuys_;

bool PlaceTrades = true;
double CurrentPriceGapRange = 0.0;
string lastError ="";

double takeProfitCash= takeProfitCash_;
double highestBalCaptured= 0.0;
double currentEquity= 0.0;
double NextExpectedBal= 0.0;
datetime startTime;
bool TradeOnEveryTickL = false;

double curProfit=0;
double curBal=0;
double curBalProfit=0;
double onStartEquity=0;
bool innerlocked = false;
bool OnResetlocked = false;

string trendSignal ="NONE";
bool buyPlaced = true;
bool sellPlaced = true;
int TradeBasketsPerTrendTrk = TradeBasketsPerTrend;
int StopLoss = StopLoss_;
int TakeProfit = StopLoss_;
datetime lastBuySignalTime,lastSellSignalTime;
double profitFibLevel = 0.0;
double lossFibLevel = 0.0;
double tradeSize;
double stopLossMM = 0.0;
double takeProfitMM = 0.0;
double stoplossPrice = 0.0;
double takeprofitPrice = 0.0;
double takeprofitPrice_2 = 0.0;
bool AutoSetLoss = AutoSetLoss_;
bool AutoSetProfit = AutoSetProfit_;
bool isAutoLossOn = false;
bool isAutoProfitOn = false;
bool UseTakeProfitCash=UseTakeProfitCash_;
bool UseTakeProfitPercentage=UseTakeProfitPercentage_;
int OnLossesResetCount = 0;
//+---trade closing
int RTOTAL=4;       
int SLEEPTIME=1;     
int  Deviation_=10;

int BreakEvenProfit = BreakEvenProfit_;
//int LockProfitPercentage = LockProfitPercentage_;
int LockProfit = LockProfit_;

int ConsecutiveLossesAllowed = ConsecutiveLossesAllowed_ * MaximumTradeCount;

//signal holders
double upSignal[], downSignal[], buyTail[], sellTail[];

bool UseFibProfitLevel = UseFibProfitLevel_;
bool UseFibStopLossLevel = UseFibStopLossLevel_;
double lastLossResetLevelBuy = 0.0;
double lastLossResetLevelSell = 0.0;
bool useOptimizedFibo = useOptimizedFibo_;

double StopLoss_Fib = _StopLoss_Fib;
double BreakEven_Fib = _BreakEven_Fib;
double TakeProfit_Fib = _TakeProfit_Fib;
string GlobalTodayDate = "";
bool targetLocked = false;
bool alertsMonitor = true;
double takeLossCash=takeLossCash_;
double DailyProfitCash=DailyProfitCash_;
double lossToStopDayTrading=lossToStopDayTrading_;
bool lossesLocked = false;
bool isBuyAlertSent = false;	
bool isSellAlertSent = false;	
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	//silver trend
	//trend1000
   //sonic
	//Half Trend. MT5Amplitude
	//pre-methods
	ArraySetAsSeries(candleTimes,true);
	
	//Set Asset
   if(UseCustomAsset){
     CustomAsset = CustomAsset_;
   }else{
     CustomAsset = _Symbol;
   }
   //Set api call interval time
   UpStreamTimeFrame =  Period();
   if(UseCustomTimer){
      if(UpStreamTimeFrame == 1){
         UPSTREAM_CALL_INTVAL_SECONDS = 20;
      }else if(UpStreamTimeFrame  == 5){
         UPSTREAM_CALL_INTVAL_SECONDS = 30;
      }else if(UpStreamTimeFrame  == 15){
         UPSTREAM_CALL_INTVAL_SECONDS = 60;
      }else{
         UPSTREAM_CALL_INTVAL_SECONDS  =120;
      }
   }else{
      UPSTREAM_CALL_INTVAL_SECONDS  = UPSTREAM_CALL_INTVAL_SECONDS_;
   }

   

	
		
	Trade.Deviation(Slippage);
	
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
     Trade.MagicNumber(MagicNumber);
     TradeBasketsPerTrendTrk = TradeBasketsPerTrend;
     
      ArraySetAsSeries(candleTimes,true);
      onStartEquity = AccountInfoDouble(ACCOUNT_BALANCE);
	   innerlocked = false;
   	PlaceTrades = PlaceTradesInPut;
   	glSignal = SIGNAL_NONE;
      startTime =TimeLocal();
      StopLoss = StopLoss_;
      TakeProfit = TakeProfit_;
      AutoSetLoss = AutoSetLoss_;
      AutoSetProfit = AutoSetProfit_;
      UseTakeProfitCash=UseTakeProfitCash_;
      UseTakeProfitPercentage=UseTakeProfitPercentage_;
      if(alertsOnly){
         /*AutoSetLoss  =true;
         AutoSetProfit  =true;*/
      }

      if(AutoSetLoss)isAutoLossOn = true;
      if(AutoSetProfit)isAutoProfitOn = true;
      
      if((AutoSetLoss ||AutoSetProfit)  && UseTakeProfitCash){
         UseTakeProfitCash = false;
      }
      
      if((AutoSetLoss ||AutoSetProfit)  && UseTakeProfitPercentage){
         UseTakeProfitPercentage = false;
      }

      if(highestBalCaptured == 0.0){
            highestBalCaptured = AccountInfoDouble(ACCOUNT_BALANCE);
      }

       //TradeBasketsPerTrendTrk = 0;
       
       //do percentage conversions
       if(UseTakeProfitPercentage){
          takeLossCash=((takeProfitPercentage/100) * onStartEquity);
          DailyProfitCash=(DailyProfitPercentage/100)*onStartEquity;
          lossToStopDayTrading=(PercentagelossToStopDayTrading/100) * onStartEquity;
       }
   return(0);
}


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{

//Check for signals upstream
  if(TimeCurrent() - lastCallTime >= UPSTREAM_CALL_INTVAL_SECONDS)
     {
      UpstreamSignalOrderType = checkAvailableSignal();//##############</>
      lastCallTime = TimeCurrent();
     }   
//--Check for new bar
	bool newBar = true;
	int barShift = 0;
	if(TradeOnNewBar == true) 
	{
		newBar = NewBar.CheckNewBar(_Symbol,_Period);
		barShift = 1;
	}
	
	
	// Update prices
	Bar.Update(_Symbol,_Period);
	//if(turnlogOn)Print(">>>UpstreamSignalOrderType <<"+ UpstreamSignalOrderType+"<<");
   //--Check new Day
    if(newBar == true || UpstreamSignalOrderType != ""){
    
   //if(turnlogOn)Print(">>>UpstreamSignalOrderType Entered>>"+ UpstreamSignalOrderType+">>");
    
       string TodayDate = TimeToString(TimeCurrent(), TIME_DATE);
       if(GlobalTodayDate != TodayDate){//new day
          GlobalTodayDate = TodayDate;
          onStartEquity = AccountInfoDouble(ACCOUNT_BALANCE);
          
          if(targetLocked){
             innerlocked = false;
         	 PlaceTrades = PlaceTradesInPut;
         	 lastError = "Relocked to trade for new day!";
         	 targetLocked = false;
          }
          
          
       }else{//same trading day
       
       }
       //do percentage conversions
       if(UseTakeProfitPercentage){
          takeLossCash=((takeProfitPercentage/100) * onStartEquity);
          DailyProfitCash=(DailyProfitPercentage/100)*onStartEquity;
          lossToStopDayTrading=(PercentagelossToStopDayTrading/100) * onStartEquity;
       }else{
          takeLossCash= takeLossCash_;
          DailyProfitCash=DailyProfitCash_;
          lossToStopDayTrading=lossToStopDayTrading_;
       }
       
      //CheckDailyTarget();
		CheckDailyTarget();
		//check profits and losses
		CheckProfits();
    }

   
   double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   double StopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   //Calculate Profits
   currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   curBal = AccountInfoDouble(ACCOUNT_BALANCE);
   
   curProfit = NormalizeDouble((currentEquity - onStartEquity),_Digits);
   curBalProfit = NormalizeDouble((curBal - onStartEquity),_Digits);
   
   Comment("Copyright © 2024 Jordan Capital Inc. ["+MagicNumber+"], Loaded @ "+startTime+" Recovery=>["+useSteadyProgressRecover+" All-("+AllSymbols+")],\nStart Bal. "+onStartEquity+" Cur Bal. "+curBal+" Bal Profit. "+curBalProfit+" Peak Bal. "+highestBalCaptured+"\nCur EQt. "+ currentEquity +", Flt Profit. "+curProfit+"\nTrade Target: "+ NormalizeDouble( takeProfitCash,_Digits) +", Loss: "+NormalizeDouble( takeLossCash,_Digits)+"\nDaily;- Target: "+ NormalizeDouble( DailyProfitCash,_Digits) +", Loss: "+ NormalizeDouble( lossToStopDayTrading,_Digits)+"\n[SL][TP][TakeCash <> %age] :["+isAutoLossOn+"]["+isAutoProfitOn+"]["+UseTakeProfitCash+" <> "+UseTakeProfitPercentage+"]\n\n"+
       "SYS-1: HYBRID::[Refresh Interval : "+UPSTREAM_CALL_INTVAL_SECONDS+"] \nSingleOrderType: "+SingleOrderType+ "\n\n"+
       "ASSET SET: "+CustomAsset+" , Trend : "+trendSignal+", Rrds : "+TradeBasketsPerTrendTrk+" , Filter: n/a \nInner Locked: "+innerlocked+"\nPlace Trades: "+PlaceTrades+"\nPrice Gap: "+CurrentPriceGapRange+" (Allowed - "+AllowedPriceGap+")\n"+lastError);


	//LETS GO!!!

	// Order placement
	if(newBar == true || UpstreamSignalOrderType != "")
	{ 
	    //Close SELL Orders
		if(glSignal == SIGNAL_BUY && trendSignal == "BUY" && !alertsOnly){
			   //Trade.Close(glSellTicket);
			   TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"SELL" );
		  }
		//Close BUY Orders
		if(glSignal == SIGNAL_SELL && trendSignal == "SELL" && !alertsOnly){
			   //Trade.Close(glBuyTicket);
			   TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage, "BUY" );
		  }
	
	    //Check if eligible to continue trading today
	    if(ConsecutiveLossesCheckFinal(ConsecutiveLossesAllowed) && OnResetlocked != true){//true then disable
   	     innerlocked = true;
           PlaceTrades= false;
           //send notification//target archieved
           string msg = "Consecutive Losses Check::Max Reached:( [Expected Consecutive Losses =>"+ ConsecutiveLossesAllowed+"] => Haulting trading for today!!!";
   	     //Print(msg);
	        lastError = msg;
	        alertsMonitor = false;
	        lossesLocked = true;
	    }else{
	        if(!targetLocked){//if was target locked, dont unlock
      	     innerlocked = false;
              PlaceTrades= PlaceTradesInPut;
           }
           //Print("Consecutive Losses Check::Password :) => Continue trading for today...");
           if(OnResetlocked)lastError = "Consecutive Losses Check:Reset";
           alertsMonitor = true;
           lossesLocked = false;
	    }
	    //unlock daily targets
	    
	
	
	   //CHECK MONEY MANAGEMENT
	   if(useSteadyProgressRecover){//recover any drawdown even in positive
         if(highestBalCaptured == 0.0){
               highestBalCaptured = curBal;
         }else if(curBal > highestBalCaptured ){
            highestBalCaptured = curBal;
         }
         if(UseTakeProfitCash_){
            //if cur bal goes below highest covered
            if(curBal < highestBalCaptured){
               double new_adv_target = MathAbs(highestBalCaptured - curBal);
                takeProfitCash = takeProfitCash_ + MathAbs(new_adv_target);
                //switch off fixed targets
                if(StopLossOverideOnRecover){
                  if(isAutoLossOn)AutoSetLoss = false;
                }
                if(isAutoProfitOn)AutoSetProfit = false;
                UseTakeProfitCash = true;
                if(!StaticFibo)UseFibProfitLevel = false;
                
            }else{//if curbal is above highBalCaptured or equal, go back to original targets
                takeProfitCash = takeProfitCash_;
                if(!StaticFibo)UseFibProfitLevel = true;//switch on fib target
                if(isAutoLossOn)AutoSetLoss = true;
                if(isAutoProfitOn)AutoSetProfit = true;
                UseTakeProfitCash = false;
            }
         }
         
         if(UseTakeProfitPercentage_){
            //if cur bal goes below highest covered
            if(curBal < highestBalCaptured){
               double new_adv_target = MathAbs(highestBalCaptured - curBal);
                takeProfitCash = ((takeProfitPercentage/100) * onStartEquity) + MathAbs(new_adv_target);
                //switch off fixed targets
                if(StopLossOverideOnRecover){
                  if(isAutoLossOn)AutoSetLoss = false;
                }
                if(isAutoProfitOn)AutoSetProfit = false;
                UseTakeProfitPercentage = true;
                if(!StaticFibo)UseFibProfitLevel = false;
                
            }else{//if curbal is above highBalCaptured or equal, go back to original targets
                takeProfitCash = ((takeProfitPercentage/100) * onStartEquity);
                if(!StaticFibo)UseFibProfitLevel = true;//switch on fib target
                if(isAutoLossOn)AutoSetLoss = true;
                if(isAutoProfitOn)AutoSetProfit = true;
                UseTakeProfitPercentage = false;
            }
         }
     }
		
		// Money management
		SetLotSize(StopLoss);
		
		
		// Open positions
		ulong buyTickets[], sellTickets[];
		
		Positions.GetBuyTickets(MagicNumber, buyTickets);
		glBuyTicket = buyTickets[0];
		
		Positions.GetSellTickets(MagicNumber, sellTickets);
		glSellTicket = sellTickets[0];
		int tradeCount = 0;
		tradeCount = MaximumTradeCount;
		
		
		//############################# Trade signals STARTS ################################
		
		//==================================================================================\\
		//**********************************************************************************//
		// =============================== Trading Methods =================================\\		
		//==================================================================================//
	   //**********************************************************************************\\

	   // Method Half Trend STARTS //
      //--
		// Method Half Trednd ENDS HERE \\
		
		// Method One RSI STARTS //
	   //--
		// Method One RSI ENDS HERE \\
	   
	   // Method Two SILVER TRADE STARTS //
	   //--
		// Method Two <::> SILVER TREND ENDS HERE \\
		
		// Method three TREND1000 STARTS //
		//--
		// Method Three <::> TREND1000 ENDS HERE \\
		
		// Method four SONIC TREND STARTS //
	   //--
		// Method four <::> SONIC ENDS HERE \\
		
		// Method five TRADEVIEW SIGNALS STARTS \\
		if(useTRADEVIEW){   
		   //####################
   		//BUY
   		//####################
      	if(UpstreamSignalOrderType == "BUY") {
      	
      	     //# DO FIBO MAGIC FOR BUY#####
      			if(true/*UseFibProfitLevel*/){
      			
 
   			         lastBuySignalTime = getCandleTime(candleTimes,lastCandleTime,0);
                     
                     //--------fibs
                     //for buys get the lowest price  betwwen previous sell, set it to selltrailP
                     //+ get  number of candles between current signal and last sell
                     int n_candles = 0;
                     n_candles =Bars(_Symbol,PERIOD_CURRENT,lastSellSignalTime,lastBuySignalTime);		                  
                     if(n_candles <= 0 || lastBuySignalTime == "1970.01.01 00:00:00" || lastSellSignalTime == "1970.01.01 00:00:00" || lastSellSignalTime == NULL || lastBuySignalTime == NULL){
                        n_candles = 150;
                     }
                     //printf("n_candles=>"+n_candles);
                     //printf("lastBuySignalTime=>"+lastBuySignalTime);
                     //printf("lastSellSignalTime=>"+lastSellSignalTime);
                     //iBarShift//use this to get left Border of fibo
                     //+ get the lowest in the series
                     double lowestP = Price.LowestLow(_Symbol,PERIOD_CURRENT,n_candles,0);
                     
                     /*if(AllowSonicStopLevel && !UseFibStopLossLevel){
                       lossFibLevel = Trade.NormalizePrice(SonicStopMA[0]);
               		 }*/
        
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
            		   if(UseFibProfitLevel) {profitFibLevel = getFibTakeProfit(TakeProfit_Fib,fib_161_8,fib_200_0,fib_261_8);}else{profitFibLevel=0.0;}
            		   //double lossFibLevel = 0.0;
            		   if(UseFibStopLossLevel) {lossFibLevel = getFibStopLoss(StopLoss_Fib,fib_061_8, fib_050_0, fib_038_2, fib_023_6);}else{lossFibLevel=0.0;}
            		   
            		   stopLossMM = MathAbs(getFibStopLoss(StopLoss_Fib,fib_061_8, fib_050_0, fib_038_2, fib_023_6) - SymbolInfoDouble(_Symbol,SYMBOL_ASK)) / point;//can change it to fib_061_8
            		   lastLossResetLevelBuy = fib_200_0;
            		   lastLossResetLevelSell = 0.0;
            		   
            		   //profitFibLevel = fib_161_8;
            		   //lossFibLevel = fib_023_6;
            		   
            		   //Determine BE
            		   double be_range = MathAbs(getFibBreakEven(BreakEven_Fib,fib_161_8,fib_200_0,fib_261_8) - SymbolInfoDouble(_Symbol,SYMBOL_ASK));
            		   if(BreakEvenProfit_ == 0 && be_range > 0){
            		      BreakEvenProfit = be_range/point;//converting it to points
            		      LockProfit = ((be_range * (LockProfitPercentage/100)) /point) + StopLevel;
            		      printf("Break Even When points are =>"+BreakEvenProfit+" ,Points to lock =>"+ LockProfit+ " ::StopLevel => "+StopLevel);
            		      
            		   }else BreakEvenProfit = BreakEvenProfit_;
            		   //Determine/set lots
                     SetLotSize(stopLossMM);//💰
            		   string msg = "\n%F0%9F%94%BC[BUY Price: "+SymbolInfoDouble(_Symbol,SYMBOL_ASK)+"] \n"+
            			             "%F0%9F%92%B0[LOT: "+tradeSize+"] \n"+
            			             "%F0%9F%9B%91[SL-1:"+fib_050_0+"] \n"+
            			             "%F0%9F%9B%91[SL-2:"+fib_061_8+"] \n"+
            			             "%E2%9C%85[TP-1:"+fib_161_8+"] \n"+
            			             "%E2%9C%85[TP-2:"+fib_200_0+"] \n"+
            			             "%E2%9C%85[TP-3:"+fib_261_8+"] \n\n"+
            			             ""+EA_Version+"";
            			 
            			 if(alertsOptimised){
               			 if(alertsMonitor)
               			   if(checkNewSignalCandle(candleTimes,lastSigCandleTime) && !isBuyAlertSent) {
               			      Price.SendAlert("BUY", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
               			      isBuyAlertSent = true;
               			      isSellAlertSent = false;
               			    }
            			 }else{
            			   if(checkNewSignalCandle(candleTimes,lastSigCandleTime)  && !isBuyAlertSent) {
            			      Price.SendAlert("BUY", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
            			      isBuyAlertSent = true;
            			      isSellAlertSent = false;
            			   }
            			 }
            			//printf(msg);
                     //--------fibs
      			}
      			//FIBO MAGIC ENDS HERE #
   		    if(doBuys){
   	         glSignal = SIGNAL_BUY;
   	         
      	        
      	        double buyStop = BuyStopLoss(_Symbol,StopLoss,0.0,0);
      			  double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,0.0,0);
      			  
      			  double P_SAR_Price = lossFibLevel;//can be MA, SAR,
      			  double P_SAR_Price_Target = profitFibLevel;
      			  
      			  stopLossMM = MathAbs(P_SAR_Price - SymbolInfoDouble(_Symbol,SYMBOL_ASK)) / point;
      			  takeProfitMM = MathAbs(profitFibLevel - SymbolInfoDouble(_Symbol,SYMBOL_ASK)) / point;
   
      			  double stoplossPrice = buyStop;
      			  double takeprofitPrice = buyProfit;
      			  
      			  if(AutoSetLoss && P_SAR_Price != 0.0){stoplossPrice = P_SAR_Price;}else {stoplossPrice=0.0;}
      			  if(AutoSetLoss && P_SAR_Price != 0.0){StopLoss = stopLossMM;}else{StopLoss = StopLoss_;}
      			  if(AutoSetProfit && P_SAR_Price_Target != 0.0){TakeProfit = takeProfitMM;}else{TakeProfit = TakeProfit_;}
      			  /*if(AutoSetProfit){//Determining profits based on ratios
      			   TakeProfit = stopLossMM * AutoProfitRatio;
      			   double TakeProfit_2 = stopLossMM * (AutoProfitRatio + 1);
      			   takeprofitPrice = BuyTakeProfit(_Symbol,TakeProfit,0.0,0);
      			   takeprofitPrice_2 = BuyTakeProfit(_Symbol,TakeProfit_2,0.0,0);
      			  }else{
      			    //TakeProfit = TakeProfit_;
      			  }*/
      			  

               	//setting signals ends here	
   	      }else{
   	         glSignal = SIGNAL_NONE;
   	      }
   	      //tradechange
   	      
   	      if(trendSignal == "SELL"){//was from sell going to buy
   	         TradeBasketsPerTrendTrk = TradeBasketsPerTrend;
      	   }
   	      trendSignal = "BUY";
   		
   		}
   		
   		//####################
   		//SELLS
   		//####################
   	   else if(UpstreamSignalOrderType == "SELL") {
   	   
   	   //# DO FIBO MAGIC FOR SELL ####
      			if(true/*UseFibProfitLevel*/){
      			      lastSellSignalTime = getCandleTime(candleTimes,lastCandleTime,0);
	                  //--------fibs
	                  //for sells get the Highest price  between previous buy, set it to buytrailP
	                  //+ get  number of candles between current signal and last buy
	                  int n_candles = 0;
	                  n_candles =Bars(_Symbol,PERIOD_CURRENT,lastSellSignalTime,lastBuySignalTime);
	                  //+ get the lowest in the series
	                  
	                  if(n_candles <= 0 || lastBuySignalTime == "1970.01.01 00:00:00" || lastSellSignalTime == "1970.01.01 00:00:00" || lastSellSignalTime == NULL || lastBuySignalTime == NULL){
	                     n_candles = 150;
	                  }
	                  
	                  //printf("n_candles=>"+n_candles);
	                  //printf("lastBuySignalTime=>"+lastBuySignalTime);
	                  //printf("lastSellSignalTime=>"+lastSellSignalTime);
	                  double highestP = Price.HighestHigh(_Symbol,PERIOD_CURRENT,n_candles,0);
	                  
	                  /*if(AllowSonicStopLevel && !UseFibStopLossLevel){
                       lossFibLevel = Trade.NormalizePrice(SonicStopMA[0]);
               		 }*/
	          
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
            		   if(UseFibProfitLevel) {profitFibLevel = getFibTakeProfit(TakeProfit_Fib,fib_161_8,fib_200_0,fib_261_8);}else{profitFibLevel=0.0;}
            		   if(UseFibStopLossLevel) {lossFibLevel = getFibStopLoss(StopLoss_Fib,fib_061_8, fib_050_0, fib_038_2, fib_023_6);}else{lossFibLevel=0.0;}
            		   stopLossMM = MathAbs(getFibStopLoss(StopLoss_Fib,fib_061_8, fib_050_0, fib_038_2, fib_023_6) - SymbolInfoDouble(_Symbol,SYMBOL_BID)) / point;//can change it to fib_061_8
            		   lastLossResetLevelBuy = 0.0;
            		   lastLossResetLevelSell = fib_200_0;
            		   
            		   //Determine BE
            		   double be_range = MathAbs(getFibBreakEven(BreakEven_Fib,fib_161_8,fib_200_0,fib_261_8) - SymbolInfoDouble(_Symbol,SYMBOL_BID));
            		   if(BreakEvenProfit_ == 0 && be_range > 0){
            		      BreakEvenProfit = be_range/point;//converting it to points
            		      LockProfit = ((be_range * (LockProfitPercentage/100)) /point) + StopLevel;
            		      printf("Break Even When points are =>"+BreakEvenProfit+" ,Points to lock =>"+ LockProfit+ " ::StopLevel => "+StopLevel);
            		      
            		   }else BreakEvenProfit = BreakEvenProfit_;
            		   
            		   //Determine/set lots
	                   SetLotSize(stopLossMM);
	                   
            		   string msg = "\n%F0%9F%94%BD[SELL Price:"+SymbolInfoDouble(_Symbol,SYMBOL_BID)+"] \n"+
			             "%F0%9F%92%B0[LOT : "+tradeSize+"] \n"+
			             "%F0%9F%9B%91[SL-1: "+fib_050_0+"] \n"+
			             "%F0%9F%9B%91[SL-2: "+fib_061_8+"] \n"+
			             "%E2%9C%85[TP-1: "+fib_161_8+"] \n"+
			             "%E2%9C%85[TP-2: "+fib_200_0+"] \n"+
			             "%E2%9C%85[TP-3:"+fib_261_8+"] \n\n"+
			             ""+EA_Version+"";
		             
		             if(alertsOptimised){
               			 if(alertsMonitor)
               			   if(checkNewSignalCandle(candleTimes,lastSigCandleTime) && !isSellAlertSent){
               			    Price.SendAlert("SELL", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
               			    isBuyAlertSent = false;
               			    isSellAlertSent = true;
               			   }
               	 }else{
                    	 if(checkNewSignalCandle(candleTimes,lastSigCandleTime) && !isSellAlertSent){
                    	  Price.SendAlert("SELL", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
                    	  isBuyAlertSent = false;
               		  isSellAlertSent = true;
               		  }
               	}
         			   //printf(msg);
      			}
      			
      			//FIBO MAGIC ENDS HERE #
   	   
   	      if(doSells){
   	         glSignal = SIGNAL_SELL;
   	         
   	         
   	        //setting signals
   	        int n_candles = 5;
   	        double highestP = Price.HighestHigh(_Symbol,PERIOD_CURRENT,n_candles,0);
   	        highestP = Trade.NormalizePrice(highestP);
   	        
   	        
   			  double sellStop = SellStopLoss(_Symbol,StopLoss,0.0,0);
   			  double sellProfit = SellTakeProfit(_Symbol,TakeProfit,0.0,0);
   	  
   			  double P_SAR_Price = lossFibLevel;//can be MA, SAR,
   			  double P_SAR_Price_Target = profitFibLevel;
   			  
   			  stopLossMM = MathAbs(P_SAR_Price - SymbolInfoDouble(_Symbol,SYMBOL_BID)) / point;
   			  takeProfitMM = MathAbs(profitFibLevel - SymbolInfoDouble(_Symbol,SYMBOL_BID)) / point;
   		
   			  double stoplossPrice = sellStop;
   			  double takeprofitPrice = sellProfit;
   			  
   			  if(AutoSetLoss && P_SAR_Price != 0.0){stoplossPrice = P_SAR_Price;}else {stoplossPrice=0.0;}
   			  if(AutoSetLoss && P_SAR_Price != 0.0){StopLoss = stopLossMM;}else{StopLoss = StopLoss_;}
   			  if(AutoSetProfit && P_SAR_Price_Target != 0.0){TakeProfit = takeProfitMM;}else{TakeProfit = TakeProfit_;}
   			  /*if(AutoSetProfit){
   			   TakeProfit = stopLossMM * AutoProfitRatio;
   			   double TakeProfit_2 = stopLossMM * (AutoProfitRatio + 1);
   			   takeprofitPrice = SellTakeProfit(_Symbol,TakeProfit,0.0,0);
   			   takeprofitPrice_2 = SellTakeProfit(_Symbol,TakeProfit_2,0.0,0);
   			  }else{
      			    //TakeProfit = TakeProfit_;
      			  }*/
      			 
      	      //setting signals ends here	
      	         
   	      }else{
   	         glSignal = SIGNAL_NONE;
   	      }
   	      //tradechange
   	      
   	      if(trendSignal == "BUY"){//was from buy going to sell
   	         TradeBasketsPerTrendTrk = TradeBasketsPerTrend;
      	   }
   	      trendSignal = "SELL";	
   	      
   	   }else {
   	         glSignal = SIGNAL_NONE;
   	   }
         //upstream signal done, reset UpstreamSignalOrderType
         UpstreamSignalOrderType = ""; 
      	
		
		}
		// Method four <::> TRADEVIEW SIGNALS ENDS HERE \\
		
		//############################# Trade signals ENDS #################################
		
		//==================================================================================\\
		//**********************************************************************************//
		// ===============================PLACING ORDERS====================================\\		
		//==================================================================================//
		
		
		
		// Open buy order
		if(glSignal == SIGNAL_BUY && 0 < TradeBasketsPerTrendTrk && trendSignal == "BUY" && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades && !innerlocked && !alertsOnly) 
		{
			if(glSellTicket > 0)
			{
			   //Trade.Close(glSellTicket);
			   TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage,"SELL" );
			}
			
		   if(DistributeTrades){//over ride number of trades
   		   if(DistributeTradesCount <= tradeCount){
   		      tradeCount = DistributeTradesCount;
   		   }else{
			      tradeCount = 1;
			   }
			}
			
			int retries = 5;
			while(tradeCount > 0){
   			//glBuyTicket = Trade.Buy(_Symbol,tradeSize);//Buy(_Symbol,tradeSize,0.000000,0.000000,pComment)
   			glBuyTicket = Trade.Buy(_Symbol,tradeSize,0.000000,0.000000,TradeComment);
   		
   			if(glBuyTicket > 0)  
   			{
   				double openPrice = PositionOpenPrice(glBuyTicket);
   				
   				double buyStop = BuyStopLoss(_Symbol,StopLoss,0.0,openPrice);
   				if(buyStop > 0) AdjustBelowStopLevel(_Symbol,buyStop);
   				
   				double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,0.0,openPrice);
   				if(buyProfit > 0) AdjustAboveStopLevel(_Symbol,buyProfit);
   				if(buyStop > 0 || buyProfit > 0) Trade.ModifyPosition(glBuyTicket,buyStop,buyProfit);
   				
   				glSignal = SIGNAL_NONE;
   				Print("Buy Trade Placed!");
       
      		   buyPlaced = true;
      		   sellPlaced = false;
         		
         		tradeCount = tradeCount - 1;
 
   			} else{
      			retries = retries - 1;
      			if(retries <= 0){
      			   break;
      			}
   			}
			}
			//count basket done
			if(glBuyTicket > 0){
			   TradeBasketsPerTrendTrk = TradeBasketsPerTrendTrk - 1;
			   if(OnResetlocked == true){//if was on merit
			      OnLossesResetCount = OnLossesResetCount - 1;
			   }
			   if(OnLossesResetCount <= 0){
			      OnResetlocked = false;
			   }
			   TakeChartScreenShot("BUY ORDER OPEN"); 
			}
		}
		
		
		// Open sell order
	
		if(glSignal == SIGNAL_SELL  && 0 < TradeBasketsPerTrendTrk && trendSignal == "SELL" && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades && !innerlocked && !alertsOnly) 
		{
			if(glBuyTicket > 0)
			{
			   //Trade.Close(glBuyTicket);
			   TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage, "BUY" );
			}
			
		   if(DistributeTrades){//over ride number of trades
   		   if(DistributeTradesCount <= tradeCount){
   		      tradeCount = DistributeTradesCount;
   		   }else{
			      tradeCount = 1;
			   }
			}
			int retries = 5;
         while(tradeCount > 0){
   			//glSellTicket = Trade.Sell(_Symbol,tradeSize);
   			glSellTicket = Trade.Sell(_Symbol,tradeSize,0.000000,0.000000,TradeComment);
   			
   			if(glSellTicket > 0)
   			{
   				double openPrice = PositionOpenPrice(glSellTicket);
   				
   				double sellStop = SellStopLoss(_Symbol,StopLoss,0.0,openPrice);
   				if(sellStop > 0) sellStop = AdjustAboveStopLevel(_Symbol,sellStop);
   				
   				double sellProfit = SellTakeProfit(_Symbol,TakeProfit,0.0,openPrice);
   				if(sellProfit > 0) sellProfit = AdjustBelowStopLevel(_Symbol,sellProfit);
   				if(sellStop > 0 || sellProfit > 0) Trade.ModifyPosition(glSellTicket,sellStop,sellProfit);
   				
   				glSignal = SIGNAL_NONE;
   				Print("Sell Trade Placed!");
   				
      		   sellPlaced = true;
      		   buyPlaced = false;
         		
         		tradeCount = tradeCount - 1;
         		
   			} else{
      			retries = retries - 1;
      			if(retries <= 0){
      			   break;
      			}
   			}
   			
   			
			}
			if(glSellTicket > 0){
			   TradeBasketsPerTrendTrk = TradeBasketsPerTrendTrk - 1;
			   if(OnResetlocked == true){//if was on merit
			      OnLossesResetCount = OnLossesResetCount - 1;
			   }
			   if(OnLossesResetCount <= 0){
			      OnResetlocked = false;
			   }
			   
			   TakeChartScreenShot("SELL ORDER OPEN"); 
			   
   		}
		}

		
	}	// Order placement end
	
	
	// Get position tickets
	ulong tickets[];
	Positions.GetTickets(MagicNumber, tickets);
	int numTickets = ArraySize(tickets);
	
	
	// Break even
	if(UseBreakEven == true && numTickets > 0)
	{
		for(int i = 0; i < numTickets; i++)
		{
		   Trail.BreakEven(tickets[i], BreakEvenProfit, LockProfit);
		}
	}
	
	
	// Trailing stop
	if(UseTrailingStop == true && numTickets > 0)
	{
		for(int i = 0; i < numTickets; i++)
		{
		   Trail.TrailingStop(tickets[i], TrailingStop, MinimumProfit, Step);
		}
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
      targetLocked = true;
      lastError = "Locked Today due to Daily Targets Profits";
      return true;  
   }
   else{
      return false;
   }
}

void CheckProfits(){
//### By Cash ###########
double TotalProfit = TotalProfit();
	if(UseTakeProfitCash){
	
	//profits
   	if((TotalProfit >=takeProfitCash && (takeProfitCash_ != 0.0)) || (TotalProfit < -(takeLossCash) && (takeLossCash != 0.0)) ){//check if orders have tp set , it the best way
   	   if(!AllSymbols){
            TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
          }
          else{
              //TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );  
              CloseAllTrades();      
          }
        }
  //losses
     if((curBalProfit < -(lossToStopDayTrading) || TotalProfit < -(lossToStopDayTrading)) && (lossToStopDayTrading != 0.0)){
   	   if(!AllSymbols){
            TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
            PlaceTrades= false;
            //send notification
            //Stop auto trading
            targetLocked = true;
            lastError = "Locked Today due to Daily Targets losses";
          }
          else{
              CloseAllTrades();  
              PlaceTrades= false;
              //send notification
              //Stop auto trading
              targetLocked = true;
              lastError = "Locked Today due to Daily Targetslosses...";    
          }
   	}
  
   }
   //### By Percentage  ###########
   else if(UseTakeProfitPercentage){
      //profits         	
   	if((TotalProfit >= takeProfitCash && (takeProfitPercentage != 0.0)) ||
   	(TotalProfit < -((takeLossPercentage/100) * onStartEquity) && (takeLossPercentage != 0.0))){
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
            targetLocked = true;
            lastError = "Locked Today due to Daily Targets losses";
          }
          else{
              CloseAllTrades();   
              PlaceTrades= false;
              //send notification
              //Stop auto trading
              targetLocked = true;
              lastError = "Locked Today due to Daily Targets losses...";   
          } 
   	}
   }
	
	//*****************
}

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
   request.comment = PositionGetString(POSITION_COMMENT) + " EA - Closed#2";
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
   request.comment = PositionGetString(POSITION_COMMENT) + "EA - Closed#2";
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


void SetLotSize(double StopLoss){
  // Money management
		if(UseMoneyManagement == true) tradeSize = MoneyManagement(_Symbol,FixedVolume,RiskPercent,StopLoss);
		else tradeSize = VerifyVolume(_Symbol,FixedVolume);
  }
  
  datetime getCandleTime(datetime &candles[],datetime &last, int seq){
	CopyTime(_Symbol,_Period,0,3,candles);
	last = candles[seq];
	return last;
}

double getFibStopLoss(double StopLossFib,double fib_061_8, double fib_050_0, double fib_038_2, double fib_023_6){
   if(StopLossFib == 61.8 ){
        return fib_061_8;
   }else if(StopLossFib == 50.0){
        return fib_050_0;
   }else if(StopLossFib == 38.2){
        return fib_050_0;
   }else{//23.6
        return fib_023_6;
   }
}

double getFibTakeProfit(double TakeProfitFib,double fib_161_8, double fib_200_0, double fib_261_8){
   if(TakeProfitFib == 161.8 ){
        return fib_161_8;
   }else if(TakeProfitFib == 200.0){
        return fib_200_0;
   }else if(TakeProfitFib == 261.8){
        return fib_261_8;
   }else{//200.0
        return fib_200_0;
   }
}

double getFibBreakEven(double BreakEvenFib,double fib_161_8, double fib_200_0, double fib_261_8){
   if(BreakEvenFib == 161.8 ){
        return fib_161_8;
   }else if(BreakEvenFib == 200.0){
        return fib_200_0;
   }else if(BreakEvenFib == 261.8){
        return fib_261_8;
   }else{//200.0
        return fib_161_8;
   }
}
 /* 
void ConsecutiveLossesCheckMT4(int ConsecutiveLosses, int MagicNumber)
{
   int losses = 0;
   int maxConsecutiveLosses = 0;
   int h = OrdersHistoryTotal() - 1;

   datetime currentDay = 0; // Initialize a variable to track the current trading day.
   bool maxLossesReached = false; // Initialize a flag to track if maxConsecutiveLosses is reached today.
   
   for (int c = 0; c < OrdersHistoryTotal(); c++)
   {
      OrderSelect(h, SELECT_BY_POS, MODE_HISTORY);
      if (TimeDayOfWeek(OrderCloseTime()) != TimeDayOfWeek(currentDay))
      {
         // Exit the loop if orders closed on a different trading day are encountered.
         break;
      }

      if (OrderMagicNumber() == MagicNumber && OrderProfit() < 0)
      {
         // Check if the order was closed on the current trading day.
         losses++;
         if (losses > maxConsecutiveLosses)
         {
            maxConsecutiveLosses = losses;
         }
      }
      else
      {
         losses = 0; // Reset consecutive losses count if a new trading day is encountered.
      }
      h--;

      // Check if maxConsecutiveLosses is reached today and set the flag accordingly.
      if (maxConsecutiveLosses >= ConsecutiveLosses)
      {
         maxLossesReached = true;
         break; // Exit the loop if maxConsecutiveLosses is reached.
      }
   }

   // If maxConsecutiveLosses is reached today, remove the EA.
   if (maxLossesReached)
   {
      ExpertRemove();
      Print("EA removed after ", ConsecutiveLosses, " consecutive losses on the same day.");
   }
}*/
bool ConsecutiveLossesCheck(int ConsecutiveLosses)
{
    //Print("Expected Consecutive Losses =>"+ ConsecutiveLosses);
    bool maxLossesReached = false; // Initialize a flag to track if maxConsecutiveLosses is reached today.
    
    if(HistorySelect(0,TimeCurrent())){//--- request trade history
       int losses = 0;
       int maxConsecutiveLosses = 0;
       int totalDeals = HistoryDealsTotal(); // Get the total number of closed deals
       
        
       datetime currentTime = TimeCurrent();
       string currentDate = TimeToString(currentTime, TIME_DATE);
      
       //Print("HistoryDealsTotal =>"+ totalDeals);
       
       for (int i = totalDeals - 1; i >= 0; i--)
       {
           ulong ticket = HistoryDealGetTicket(i); // Get the ticket number of the selected deal
           double OrderProfit=HistoryDealGetDouble(ticket,DEAL_PROFIT);//POSITION_TICKET
           ulong DealMagicNo = HistoryDealGetInteger(ticket,DEAL_MAGIC);
         
           string symbol = HistoryDealGetString(ticket,DEAL_SYMBOL);//--
           long deal_type = HistoryDealGetInteger(ticket,DEAL_TYPE);//--
           double volume =  HistoryDealGetDouble(ticket,DEAL_VOLUME);//--
           long position_ID = HistoryDealGetInteger(ticket,DEAL_POSITION_ID);//--

           
           datetime  closeTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
           string dealCloseDate = TimeToString(closeTime, TIME_DATE);
           
           //--just for debug
           string descr=StringFormat("  %s -> %s, %G %s (order #%d, profit[%G] DMgc- [%d] BMgc - [%d])",
                      currentDate,  // current date
                      dealCloseDate, //deal close date
                      volume, // deal volume
                      symbol, // deal symbol
                      ticket, // ticket of the order that caused the deal
                      OrderProfit,  // ID of a position, in which the deal is included
                      DealMagicNo,
                      MagicNumber
                      );
                      

           string print_index=StringFormat("% 3d",i);
           //Print(print_index+": deal #",ticket," at ",closeTime,descr);
           //--
           if(ConsecutiveLossesOnlyDaily){
              if (dealCloseDate != currentDate)
               {
                  // Exit the loop if orders closed on a different trading day are encountered.
                  break;
               }
            }
            if(OrderProfit != 0 && DealMagicNo == MagicNumber ){//skip deals with profit  = 0
               if (OrderProfit < 0)
               {  //Print("loss count Ticket=>"+i);
                  // Check if the order was closed on the current trading day.
                  losses++;
                  if (losses > maxConsecutiveLosses)
                  {
                     maxConsecutiveLosses = losses;
                  }
               }
               else
               {  //Print("Ticket skipped on count=>"+i);
                  losses = 0; // Reset consecutive losses count if a new trading day is encountered.
                  OnLossesResetCount = 0;
                  break; //break if any profit encountered before reaching maximum loss expected
               }
            }else{
             //Print("Ticket skipped on coz Zero=>"+i);
            }
        
      
            // Check if maxConsecutiveLosses is reached today and set the flag accordingly.
            if (maxConsecutiveLosses >= ConsecutiveLosses)
            {
               maxLossesReached = true;
               break; // Exit the loop if maxConsecutiveLosses is reached.
            }
       }
       
       //returning
        //Print("maxLossesReached=> ["+maxLossesReached+"] Loss Count ["+maxConsecutiveLosses+"]");
       
      }else{
        Print("At Deals History Check, No trades found at this time :( ");
      }
      return(maxLossesReached);
}



bool ConsecutiveLossesCheckFinal(int ConsecutiveLosses){
      //Check loss
      bool lossCheck = ConsecutiveLossesCheck(ConsecutiveLosses);
      if(!lossCheck){//if false
         return false;
      }else{//if true, do further checks Before locking
        if(!ConsecutiveLossesOnlyDaily){
        

            if(trendSignal == "BUY" && SymbolInfoDouble(_Symbol,SYMBOL_ASK) >= lastLossResetLevelBuy){
              OnResetlocked = true;
              OnLossesResetCount = OnLossesResetCount_;
              return false;
            }else if(trendSignal == "SELL" && SymbolInfoDouble(_Symbol,SYMBOL_BID) <= lastLossResetLevelSell){
              OnResetlocked = true;
              OnLossesResetCount = OnLossesResetCount_;
              return false;
            }else{
              if(OnLossesResetCount > 0)
                  return false;
               else
                  return true;
            }
        }else{
          return true;
        }
      }
      
}

bool CheckPostionsComment(string orderComment)
{
    Print("Comment being checked =>"+ orderComment);
    //check current positions
    if(CurrentOrderCommentExists(orderComment)){
      return true;
    }

    if(HistorySelect(0,TimeCurrent())){//--- request trade history
 
       int totalDeals = HistoryDealsTotal(); // Get the total number of closed deals
        
       datetime currentTime = TimeCurrent();
       string currentDate = TimeToString(currentTime, TIME_DATE);
      
       //Print("HistoryDealsTotal =>"+ totalDeals);
       
       for (int i = totalDeals - 1; i >= 0; i--)
       {
           ulong ticket = HistoryDealGetTicket(i); // Get the ticket number of the selected deal
           double OrderProfit=HistoryDealGetDouble(ticket,DEAL_PROFIT);//POSITION_TICKET
           ulong DealMagicNo = HistoryDealGetInteger(ticket,DEAL_MAGIC);
         
           string symbol = HistoryDealGetString(ticket,DEAL_SYMBOL);//--
           long deal_type = HistoryDealGetInteger(ticket,DEAL_TYPE);//--
           double volume =  HistoryDealGetDouble(ticket,DEAL_VOLUME);//--
           long position_ID = HistoryDealGetInteger(ticket,DEAL_POSITION_ID);//--
           string comment = HistoryDealGetString(ticket,DEAL_COMMENT);

           
           datetime  closeTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
           string dealCloseDate = TimeToString(closeTime, TIME_DATE);
           
           //--just for debug
           string descr=StringFormat("  %s -> %s, %G %s (order #%d, profit[%G] DMgc- [%d] BMgc - [%d])",
                      currentDate,  // current date
                      dealCloseDate, //deal close date
                      volume, // deal volume
                      symbol, // deal symbol
                      ticket, // ticket of the order that caused the deal
                      OrderProfit,  // ID of a position, in which the deal is included
                      DealMagicNo,
                      MagicNumber
                      );
                      

            string print_index=StringFormat("% 3d",i);
            //Print(print_index+": deal #",ticket," at ",closeTime,descr);
     
            if(OrderProfit != 0 && symbol == _Symbol){//skip deals with profit  = 0
               //--
              if (dealCloseDate != currentDate) {
                  // Exit the loop if orders closed on a different trading day are encountered.
                  //break;
                  return false;
              }
              if (orderComment == comment || StringFind(comment, orderComment) >= 0){
                 // break;
                 return true;
              }
              
              
            }else{
             //Print("Ticket skipped on coz Zero=>"+i);
            }
       
       }
       
       
      }else{
        Print("At Deals History Check, No trades found at this time :( ");
        return false;
      }
      return false;
}

bool CurrentOrderCommentExists(const string comment)
{
    int totalPositions = PositionsTotal(); // Total positions
    for (int i = totalPositions - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i); // Get ticket for position at index i
        if (ticket > 0)
        {
            string positionComment = PositionGetString(POSITION_COMMENT); // Get comment for position at index i
            if (positionComment == comment || StringFind(positionComment, comment) >= 0)
            {
                return true; // Found matching comment in position
            }
        }
    }
    return false; // Comment not found in any position
}

//==================================================================================\\
//**********************************************************************************//
// ================GET ORDERS FROM UPSTREAM IMPLEMENTATIONS STARTS==================\\		
//==================================================================================//
string checkAvailableSignal()
  {
//--- Your tick code here
// Example of sending a POST request in the OnTick function
   //UpstreamSignalOrderType = "";
   string url = ENDPOINT_URL_DEFAULT;
   if(ENDPOINT_URL == "DEFAULT"){
      url = ENDPOINT_URL_DEFAULT;
   }else{
      url = ENDPOINT_URL;
   }
   
   string postData = "{\"asset\": \""+CustomAsset+"\", \"tf\": \""+UpStreamTimeFrame+"\", \"UpstreamSignalOrderType\": \"ANY\", \"broker\": \"DEFAULT\", \"strategyName\": \""+strategyName+"\", \"license\": \""+licenceKey+"\"}";
   char DataArr[];      // the array of the HTTP message body
   StringToCharArray(postData, DataArr);

   char result[];       //an array containing server response data
   char error[];
   int timeout = 5000; // Timeout in milliseconds
   string result_headers  = "";
   string cookie=NULL;
   string headers = "Content-Type: application/json";

   if(turnlogOn) Print("Out going request to upstream: ", postData  ," @ ", url);
   int res = WebRequest("POST", url,headers, timeout, DataArr, result, result_headers);

   if(res==-1)
     {
      UpstreamSignalOrderType = "";
      Print("Error in WebRequest. Error code  =",GetLastError());
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address
      MessageBox("Add the address '"+url+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
     }
   else
      if(res == 200)//--- Successful
        {

         string response = CharArrayToString(result);
         if(turnlogOn) Print("Response: ", response);
         // Process the JSON response here //StringFind(response, "BUY") >= 0
        
        //validate signal
        if(StringFind(response, "BUY") > -1 || StringFind(response, "SELL") > -1){ 
           //get upstreamComment
           string upstreamComment = GetJsonID(response);
           //check if already placed
           if(CheckPostionsComment(upstreamComment) && upstreamComment != EA_Version){
               Print("Order with comment ["+upstreamComment+"] already executed on this account:\n");
               UpstreamSignalOrderType = "";
               return UpstreamSignalOrderType;
           }else{
               TradeComment = upstreamComment;
           }
        }


         if(StringFind(response, "BUY") > -1)//StringFind(response, "\"signalOrderType\":\"BUY\"") > -1
           {
            UpstreamSignalOrderType = "BUY";
            Print("[BUY] signal has been set:\n");
           }
         else if(StringFind(response, "SELL") > -1)
              {
               UpstreamSignalOrderType = "SELL";
               Print("[SELL] signal has been set:\n");
              }
         else
              {
               Print("Unknown response received:", response);
               // Handle unknown response scenario (optional)
               UpstreamSignalOrderType = "";
              }

        }
      else if(res == 404)//--- not found
           {
            UpstreamSignalOrderType = "";
            if(turnlogOn) Print("No record/signal found yet.");

           }
       else
           {
            UpstreamSignalOrderType = "";
            Print("Unknown response code returned ["+ res +"]");
            Print("Error in WebRequest. @endpoint: ", url, ", Error: ", GetLastError());

           }

return UpstreamSignalOrderType;
}




string GetJsonID(const string response)
{
    string DefaultValue = EA_Version;
    string idString = "\"id\":";
    int idIndex = StringFind(response, idString);
    if (idIndex >= 0)
    {
        int idStart = idIndex + StringLen(idString);
        int idEnd = StringFind(response, ",", idStart);
        if (idEnd < 0)
            idEnd = StringFind(response, "}", idStart);

        string idValue = StringSubstr(response, idStart, idEnd - idStart);
        int id = 0; // Initialize id to 0
        if (idValue != "0") // Check if idValue is not "0" before conversion
        {
            id = StringToInteger(idValue);
            if (id == 0) // Check if conversion failed
            {
                //id = DefaultValue; // Set default value
                if(turnlogOn) Print("Error: Failed to convert 'id' value from JSON response. Using default value.");
                return DefaultValue;
            }else{
               return idValue;
            }
        }else{
           return DefaultValue;
        }
       if(turnlogOn) Print("ID from response: ", id);
        // Now you can use the 'id' variable for further processing
        //return DefaultValue;
    }
    else
    {
        int id = DefaultValue; // Set default value
        if(turnlogOn)Print("Error: 'id' key not found in JSON response. Using default value.");
        return DefaultValue;
    }
}

//==================================================================================\\
// ==============+==GET ORDERS FROM UPSTREAM IMPLEMENTATIONS ENDS===================\\	
//**********************************************************************************//	
//==================================================================================//

bool checkNewSignalCandle(datetime &candles[],datetime &last){


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

//https://www.tradingview.com/script/Hl1Sw0I4-Uhl-MA-Crossover-System/
//// This source code is subject to the terms of the Mozilla Public License 2.0 at https://mozilla.org/MPL/2.0/
// © alexgrover

//@version=4
//--starts
/*
study("Uhl MA Crossover System","UHLMA",true)
length = input(100),mult = input(1.),src = input(close)
//----
out = 0., cma = 0., cts = 0.
Var = variance(src,length)*mult
sma = sma(src,length)
//----
secma = pow(nz(sma - cma[1]),2) 
sects = pow(nz(src - cts[1]),2) 
ka = Var < secma ? 1 - Var/secma : 0
kb = Var < sects ? 1 - Var/sects : 0
//----
cma := ka*sma+(1-ka)*nz(cma[1],src)
cts := kb*src+(1-kb)*nz(cts[1],src)
//----
css = cts > cma ? #2157f3 : #ff1100
a = plot(cts,"CTS",#2157f3,2,transp=0)
b = plot(cma,"CMA",#ff1100,2,transp=0)
fill(a,b,color=css,transp=80)
//--end
*/
/*
Today proposed indicator is based on the corrected moving average, an indicator originally proposed by Andreas Uhl professor at Salzburg University. This moving average is not the most well known, which is a pity since its design is extremely elegant.

The corrected moving average (CMA) is an adaptive moving average based on exponential averaging and aim to correct common problems of classical moving averages such as crosses occurring during sideway markets, more details will be introduced in the calculation section. The CMA aim to act as a slow moving average in a moving average crossover system.

Here a new fast adaptive moving average named corrected trend step (CTS) based on the CMA is introduced in order to provide a full moving average crossover system based on A. Uhl design.

To Andreas Uhl

Calculation And Understanding The CTS

Even if the code is quite compact, the original idea behind the CMA can be blurry for some users, however it is actually relatively simple to understand. The CMA is based on exponential averaging and a smoothing variable is therefore required, in the CMA the calculation of the smoothing variable is based on the squared distance between the precedent CMA output and a simple moving average, and the rolling variance, where the rolling variance act as threshold.

The CTS work the same way but instead of using the squared error between a simple moving average and the previous CMA output, we use the squared error between the closing price and the previous CTS output, this allow the CTS to better fit with the closing price. As said before the rolling variance act as threshold, if the squared error is lower than the rolling variance this mean that the CTS is close to the price, which can indicate a sideway market, therefore we should filter the entirety of the current price, therefore on sideways market the CTS is equal to the precedent value of the CTS.

In trending/volatile markets we expect the price to go away from the CTS, thus having an high squared error, if the squared error is greater than the rolling variance, the smoothing variable is equal to 1 - variance/squared error, here variance/squared error < 1 since the squared error is greater than the rolling variance (remember that the smoothing variable need to be in a (0,1) range), however if the squared error is way higher than variance this ratio will be small, which would return a non reactive output, but thats not what we want ! This is why we subtract 1 by this ratio in order to make the CTS more reactive instead of less reactive.

In case the squared error is greater than the rolling variance during sideway markets we would not expect a huge difference anyway, that is squared error ≈ variance and therefore:

1 - variance/squared error ≈ 1 - 1/1 ≈ 1 - 1 ≈ 0

This is a beautiful way to make an adaptive moving average, the CMA is not a flashy indicator, but when we look at the details behind the design we can only get amazed, or maybe that its just me, truly a great adaptive moving average.

The System

length control the filtering amount of both moving averages, with higher values of length returning larger filtering amount. Mult multiply the rolling variance by an user selected value, this also allow a greater amount of filtering.

The CTS act as a fast moving average while the CMA act as a slow moving average. 

Conclusion

A moving average crossover system based on the corrected moving average proposed by Andreas Uhl has been presented, a new moving average that aim to produce good fits with the price has been created especially for this system. The logic behind the CMA has also been explained. A possible strategy analysis could be presented in the future.

In conclusion i would say the CMA is a bit underrated, in a field where arrows, signals, alerts are the only things appreciated by peoples, original content is slowly dying, this actually make today technical indicators have a pretty bad academic reputations. I'am afraid that today haiku master is Uhl rather than me, i hope to see more indicators from him in the future.

Thanks for reading !

Original paper: www.buero-uhl.de/papers.htm
http://www.buero-uhl.de/data/cmats.txt

{Corrected Average (CA), A.Uhl, Oct. 25, 2005}

vars: 
CA(0),SA(0),n(0),
v1(0),v2(0),v3(0),
e(0),tol(0),Kold(0),K(0);

inputs: 
Price(Close),length(35);

tol=Power(10,-5);

if CurrentBar=1 then
CA=Price
else 
begin

if CurrentBar<length then
n=CurrentBar
else
n=length;

SA=Average(Price,n);
v1=Square(StdDev(Price,n));
v2=Square(CA[1]-SA);
v3=iff(v1=0 OR v2=0,1,v2/(v1+v2));	
	
{calculate current gain factor K}
e=1; 
Kold=1;
while e>tol begin
	K=v3*Kold*(2-Kold);
	e=Kold-K;
	Kold=K;
end;	
CA=CA[1]+K*(SA-CA[1]);
end;

Plot1(CA,"Corrected Average",Red,White,3);
Plot2(SA,"Simple Average",Blue,White,1);
*/

