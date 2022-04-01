#property copyright "Source Code Technlogies"
#property link      "https://www.soscode.com"
#property version   "2022.04.01@10:07"
/*
*Static target re-calculation in drawdown
Add BC Volume Area to filter trades on range
Enable multi-asset trading(trd closing, target re-calcualtions )
Break even when profit return to 0.0 from drawdown
Break even when first normal target reached
Break even when the advanced target has been reached
Take screen shot on open and close of trade for journaling

*/
/*#include <Mql5Book\Trade.mqh>
CTradeC Trade;*/
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
input bool ActivateSys1 = true;
input int MAPeriodShort=2;
//10//smooth
input int MAPeriodLong=200;
input int FourMAPeriod=200;

sinput string __strategy_2__NonLag;	
input bool ActivateSys2 = false;
input int NonLagMAPeriod=200;
input bool confirmByNonlag = false;

sinput string params;
input int MAShift=0;
input ENUM_MA_METHOD MAMethodS= MODE_SMMA;
input ENUM_MA_METHOD MAMethodL= MODE_EMA;
input ENUM_APPLIED_PRICE MAPrice= PRICE_CLOSE;

sinput string MoneyManagement;		
input double volume=0.2;
input bool UseMoneyManagement = false;
input double RiskPercent = 2;
input double StopLoss = 0.0;
input double AllowedPriceGap = 0.0;


sinput string CashMeasures;
input bool UseTakeProfitCash=true;
input double takeProfitCash_=20.0;
input double takeProfitCashLongs_=20.0;
input double DailyProfitCash=100.0;
input double lossToStopDayTrading=10.0;
//input double stopLossCash=0.0;

sinput string PercentageMeasures;
input bool UseTakeProfitPercentage=false;
input double takeProfitPercentage=6.0;
input double takeProfitPercentageLongs=30.0;
input double DailyProfitPercentage=50;
input double PercentagelossToStopDayTrading = 50;
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
input bool useStaticMoneyRecover_ = true;
input bool useSteadyProgressRecover = true;

sinput string TS;		// Trailing Stop
input bool UseTrailingStop = false;
input int TrailingStop = 0;
input int MinimumProfit = 0;
input int Step = 0; 
input bool AutoStopLossSet = false;
input bool UseFibProfitLevel = true;

sinput string BE;		// Break Even
input bool UseBreakEven = false;
input int BreakEvenProfit = 5;
input int LockProfit = 2;

sinput string ALERTS;		
input bool   alertsOnCurrent = false;
input bool   alertsMessage   = false;
input bool   alertsOnPhone   = false;
input bool   alertsEmail     = false;
input bool   alertsSound     = false;
input bool   alertsTelegram  = false;
input string     APIkey      = "1819898948:AAFRCYc45DMt_hTjwRtUuk58iRIvc1bRcIs";
input string     Channel_ID  = "-590157620";
//-------------------------
string EA_Version = "#Jordan_UNIV EA-V3.2";
//


enum orderType{
   orderBuy,
   orderSell
};

datetime candleTimes[],lastCandleTime;
string CurSignal="";
string CurSignalNonLag="";
string CurTrend;
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
bool useStaticMoneyRecover = useStaticMoneyRecover_;


MqlTradeRequest request;
MqlTradeResult result;
MqlTradeCheckResult checkResult;

//+------------------------------------------------------------------+ 
//| start function                                                   |
//+------------------------------------------------------------------+
int OnInit(){
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
   useStaticMoneyRecover = useStaticMoneyRecover_;
   if(useSteadyProgressRecover)useStaticMoneyRecover = true;
   if(highestBalCaptured == 0.0){
         highestBalCaptured = AccountInfoDouble(ACCOUNT_BALANCE);
     }
   
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
}

void OnTick(){
//Calculate Profits
currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
curBal = AccountInfoDouble(ACCOUNT_BALANCE);

curProfit = NormalizeDouble((currentEquity - onStartEquity),_Digits);
curBalProfit = NormalizeDouble((curBal - onStartEquity),_Digits);

Comment("Copyright © 2022 Soscode Tech, Loaded @ "+startTime+",\nStart Bal. "+onStartEquity+" Cur Bal. "+curBal+" Bal Profit. "+curBalProfit+" Peak Bal. "+highestBalCaptured+"\nCur EQt. "+ currentEquity +", Flt Profit. "+curProfit+"\nTrade Target: "+ takeProfitCash +"\nDaily;- Target: "+ DailyProfitCash +", Loss: "+lossToStopDayTrading+"\nSYS 1: "+CurTrend+"<--4MACandles [Default] (Active-"+ActivateSys1+") \nSYS 2: "+CurTrendNonLag+ "<--Non lag (Active-"+ActivateSys2+")\nInner Locked: "+innerlocked+"\nPlace Trades: "+PlaceTrades+"\nPrice Gap: "+CurrentPriceGapRange+"\n"+lastError);
//modify targets
if(!useStaticMoneyRecover){
   if(curProfit < 0){//if we are in drawdown
      takeProfitCash = takeProfitCash_ + MathAbs(curProfit);
      takeProfitCashLongs = takeProfitCashLongs_ + MathAbs(curProfit);
   }else{
      takeProfitCash = takeProfitCash_;
      takeProfitCashLongs = takeProfitCashLongs_;
   }
}else{

   if(!useSteadyProgressRecover){
       if(curBalProfit < 0){//if we are in drawdown
         takeProfitCash = takeProfitCash_ + MathAbs(curBalProfit);
         takeProfitCashLongs = takeProfitCashLongs_ + MathAbs(curBalProfit);
        }else {
         takeProfitCash = takeProfitCash_;
         takeProfitCashLongs = takeProfitCashLongs_;
       }
   }else{//recover any drawdown even in positive
      if(highestBalCaptured == 0.0){
            highestBalCaptured = curBal;
      }else if(curBal > highestBalCaptured ){
         highestBalCaptured = curBal;
      }
      //if cur bal goes below highest coved
      if(curBal < highestBalCaptured){
         double new_adv_target = MathAbs(highestBalCaptured - curBal);
          takeProfitCash = takeProfitCash_ + MathAbs(new_adv_target);
          takeProfitCashLongs = takeProfitCashLongs_ + MathAbs(new_adv_target);
      }else{//if curbal is above highBalCaptured or equal, go back to original targets
          takeProfitCash = takeProfitCash_;
          takeProfitCashLongs = takeProfitCashLongs_;
      }
   
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
	// Money management
		if(UseMoneyManagement == true)  tradeSize = MoneyManagement(_Symbol,volume,RiskPercent,StopLoss);
		else tradeSize = VerifyVolume(_Symbol,volume);
		tradeSize = volume;
		
		double maS[];
		double maL[];
		double maSNonLag[];
		double maLNonLag[];
		double NonLagSignalValues[];
		double _4MACandlesValuesH[];
		double _4MACandlesValuesL[];
		double BCVolumeArea[];
		ArraySetAsSeries(maS,true);
		ArraySetAsSeries(maL,true);
		ArraySetAsSeries(maSNonLag,true);
		ArraySetAsSeries(maLNonLag,true);
		ArraySetAsSeries(NonLagSignalValues,true);
		ArraySetAsSeries(_4MACandlesValuesH,true);
		ArraySetAsSeries(_4MACandlesValuesL,true);
		ArraySetAsSeries(BCVolumeArea,true);
		
		double candleClose[];
		ArraySetAsSeries(candleClose,true);
		int maSHandle= iMA(_Symbol,_Period,MAPeriodShort,MAShift,MAMethodS,MAPrice);
		int maLHandle= iMA(_Symbol,_Period,MAPeriodLong,MAShift,MAMethodL,MAPrice);
		//+FOR NONLAG
		int maLHandleNonLag = iCustom(_Symbol,_Period, "NonLagMaAlerts");
		//int BCVolumeAreaHandle = iCustom(_Symbol,_Period, "BC Volume Area",20);//solarwinds
		
		int maSHandleNonLag= iMA(_Symbol,_Period,10,0,MODE_EMA,MAPrice);
		
		CopyBuffer(maSHandle,0,0,3,maS);
		CopyBuffer(maLHandle,0,0,3,maL);//CopyBuffer(NonlagMaHandle,0,0,3,NonLagSignalValues);
		CopyBuffer(maLHandleNonLag,0,0,3,maLNonLag);//Non Lag Ma
		//CopyBuffer(maLHandleNonLag,2,0,3,maLNonLag);//Non Lag Ma Actual Trend
		CopyBuffer(maSHandleNonLag,0,0,3,maSNonLag);//EMa 10
		
		int _4MACandlesHandle = iCustom(_Symbol,_Period, "4MACandles");
		CopyBuffer(_4MACandlesHandle,1,0,3,_4MACandlesValuesH);//Upper
		CopyBuffer(_4MACandlesHandle,2,0,3,_4MACandlesValuesL);//Lower
		_4MACandleRange =MathAbs(_4MACandlesValuesH[0] - _4MACandlesValuesL[0]);
		//CopyBuffer(BCVolumeAreaHandle,0,0,3,BCVolumeArea);
		
		
		CopyClose(_Symbol,_Period,0,3,candleClose);
		CurrentPriceGapRange = CalculatePriceGap(maL[0]);
		

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
	    if(((CurSignal=="BUY" && ActivateSys1) || (CurSignalNonLag =="BUY" && ActivateSys2)) && !buyPlaced ){
	     if(AllowedPriceGap > 0.0 && (AllowedPriceGap >= CurrentPriceGapRange) ){
   	      if(FullAutoPilot)
   		      makePosition(orderBuy);
   		     else if(BuyOnly) 
   		      makePosition(orderBuy);
		    }else if(AllowedPriceGap == 0.0){//just trade if gap not specified
   		     if(FullAutoPilot)
      		      makePosition(orderBuy);
      		     else if(BuyOnly) 
      		      makePosition(orderBuy);
		    }
		 }
		 if(((CurSignal=="SELL" && ActivateSys1)  || (CurSignalNonLag =="SELL" && ActivateSys2)) && !sellPlaced){
   		 if(AllowedPriceGap > 0.0 && (AllowedPriceGap >= CurrentPriceGapRange) ){
   	      if(FullAutoPilot)
   		      makePosition(orderSell);
   		     else if(SellOnly) 
   		      makePosition(orderSell);
		    }else if(AllowedPriceGap == 0.0){//just trade if gap not specified
   		     if(FullAutoPilot)
      		      makePosition(orderSell);
      		     else if(SellOnly) 
      		      makePosition(orderBuy);
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
   	if(TotalProfit >=takeProfitCash && (takeProfitCash != 0.0)){
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
   	if(TotalProfit >= ((takeProfitPercentage/100) * onStartEquity) && (takeProfitPercentage != 0.0)){
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
      	   if(TotalProfit >= takeProfitCashLongs && (takeProfitCashLongs != 0.0)){
       
            	  // if(!AllSymbols){    	
                     TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
                 //  }
                  // else{
                     //  CloseAllTrades();      
                 //  }
                   //if(TradeLongsOnce)closedFalls = true;
            	}
   	   
   	   }else if(UseTakeProfitPercentage){
         	if(TotalProfit >= ((takeProfitPercentageLongs/100) * onStartEquity) && (takeProfitPercentageLongs != 0.0)){
       
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
   
   	if(type==orderBuy){
   		//Buy
   		request.type=ORDER_TYPE_BUY;
   		price=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   		//request.sl=NormalizeDouble(price-stopLoss,_Digits);
   		//request.tp=NormalizeDouble(price+takeProfit,_Digits);
   		
   	}else if(type==orderSell){
   		//Sell
   		request.type=ORDER_TYPE_SELL;
   		price=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
   		//request.sl=NormalizeDouble(price+stopLoss,_Digits);
   		//request.tp=NormalizeDouble(price-takeProfit,_Digits);
   
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
      return true;
   }else{
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
   string name = "shots\\MyJournel\\"+DayOfWeek(today.day_of_week)+"\\"+Symbol()+" - "+Price.GetTimeFrame()+"-"+description_+".gif";
   //WindowScreenShot(,640,640);
  if(ChartScreenShot(0,name,640,640,ALIGN_LEFT))
               printf("We've saved the screenshot ",name);
  }
string DayOfWeek(int dow){
   string day[] = {"Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"};
   return day[dow];
}
//+------------------------------------------------------------------+

   

