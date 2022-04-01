//+------------------------------------------------------------------+
//| 									 Expert Advisor Programming - Template |
//|                                              Andrew Young|kidepo |
//|                                           http://www.soscode.com |
//+------------------------------------------------------------------+

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/

#include <Trade\XTrade.mqh>
CTrade TradeX;

// Trade
#include <Mql5Book\Trade.mqh>
CTradeC Trade;

//Trade Info
#include <Trade\PositionInfo.mqh>
CPositionInfo  Position;

// Price
#include <Mql5Book\Price.mqh>
CBars Price;

// Money management
#include <Mql5Book\MoneyManagement.mqh>

// Trailing stops
#include <Mql5Book\TrailingStops.mqh>
CTrailing Trail;

// Timer
#include <Mql5Book\Timer.mqh>
CTimer Timer;
CNewBar NewBar;

// Indicators 
#include <Mql5Book\Indicators.mqh>


//+------------------------------------------------------------------+
//| Expert information                                               |
//+------------------------------------------------------------------+

#property copyright "Andrew Young|KiDePo"
#property version   "1.01"
#property description "Based on Non Lag 200 and Exp. MA 10"
#property link      "https://www.soscode.com"



//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
input int MyMagicNumber = 0;
input ulong Slippage = 3;
input bool PlaceTrades = false;
input bool TradeOnNewBar = true;

sinput string MM; 	// Money Management
input bool UseMoneyManagement = true;
input double RiskPercent = 2;
input double FixedVolume = 0.001;

sinput string SL; 	// Stop Loss & Take Profit
input int StopLoss = 0;
input int TakeProfit = 0;
input bool AutoCloseOnShiftZero = true;
input int TotalTrades = 5;

sinput string TS;		// Trailing Stop
input bool UseTrailingStop = false;
input int TrailingStop = 0;
input int MinimumProfit = 0;
input int Step = 0; 
input bool AutoStopLossSet = false;
input bool UseFibProfitLevel = false;

sinput string BE;		// Break Even
input bool UseBreakEven = false;
input int BreakEvenProfit = 0;
input int LockProfit = 0;

sinput string ALERTS;		
input bool   alertsOnCurrent = true;
input bool   alertsMessage   = true;
input bool   alertsOnPhone   = true;
input bool   alertsEmail     = false;
input bool   alertsSound     = false;
input bool   alertsTelegram     = true;
input string     APIkey                  = "1819898948:AAFRCYc45DMt_hTjwRtUuk58iRIvc1bRcIs";
input string     Channel_ID              = "-590157620"; 

sinput string TI; 	// Timer
input bool UseTimer = false;
input int StartHour = 0;
input int StartMinute = 0;
input int EndHour = 0;
input int EndMinute = 0;
input bool UseLocalTime = false;





//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+

bool glBuyPlaced, glSellPlaced;
int NonlagMaHandle;
int MagicNumber=0;
string MagicNumber=0;
string EA_Version = "#Jordan_CB-5-v1.00";




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	
	
	Trade.Deviation(Slippage);
   return(0);
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{  
   // rechecking if magic number is set
   if(MagicNumber <= 0 && MyMagicNumber <= 0)
     {
      MagicNumber = ChartID();
      Trade.MagicNumber(MagicNumber);
      printf("MagicNumber AutoSet To => "+ MagicNumber);
     }else if(MyMagicNumber > 0){
      MagicNumber = MyMagicNumber;
      Trade.MagicNumber(MagicNumber);
     }
     else{
      Trade.MagicNumber(MagicNumber);
     }
   //Generate Signal
   double NonLagSignalValues[], NonLagTrendSignals[];
   ArraySetAsSeries(upSignal,true);
   ArraySetAsSeries(downSignal,true);
   
   ArraySetAsSeries(buyTail,true);
   ArraySetAsSeries(sellTail,true);
   
 

   
	// Check for new bar
	bool newBar = true;
	//int barShift = 0;
	
	if(TradeOnNewBar == true) 
	{
		newBar = NewBar.CheckNewBar(_Symbol,_Period);
		if(newBar){
	   NonlagMaHandle = iCustom(_Symbol,_Period, "NonLagMaAlerts");  
	   //Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
	   }   
	}
	else if(!TradeOnNewBar || alertsOnCurrent){
	   NonlagMaHandle = iCustom(_Symbol,_Period, "NonLagMaAlerts");
	}
	//else NonlagMaHandle = iCustom(_Symbol,_Period, "TREND_1000");
	if(alertsOnCurrent)
	   NonlagMaHandle = iCustom(_Symbol,_Period, "NonLagMaAlerts");
	   
	CopyBuffer(NonlagMaHandle,0,0,3,NonLagSignalValues);//0
   CopyBuffer(NonlagMaHandle,2,0,3,NonLagTrendSignals);//2//1:buy/-1:sell

      
	
	double NonLagSignalValueCur = NonLagSignalValues[0];
	double NonLagSignalValuePrev = NonLagSignalValues[1];
	
	double NonLagTrendSignalCur = NonLagTrendSignals[0];
	double NonLagTrendSignalPrev = NonLagTrendSignals[1];
	
	
	
	// Send Notification On Current Candle
	if(alertsOnCurrent && upSignalC > 0)
	{
	  newBar = NewBar.CheckNewAlertBar(_Symbol,_Period);
	  if(newBar)
	    Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
	}
	
	if(alertsOnCurrent && downSignalC > 0)
	{
	  newBar = NewBar.CheckNewAlertBar(_Symbol,_Period);
	  if(newBar)
	    Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
	}
	
	
	
	// Timer
	bool timerOn = true;
	if(UseTimer == true)
	{
		timerOn = Timer.DailyTimer(StartHour,StartMinute,EndHour,EndMinute,UseLocalTime);
	}
	
	
	// Update prices
	Price.Update(_Symbol,_Period);
	
	
	// Order placement
	if(newBar == true && timerOn == true)
	{
		
		// Money management
		double tradeSize;
		if(UseMoneyManagement == true) tradeSize = MoneyManagement(_Symbol,FixedVolume,RiskPercent,StopLoss);
		else tradeSize = VerifyVolume(_Symbol,FixedVolume);
		
		//Close Orders
		if((upSignal[0] > 0 || downSignal[0] > 0) && AutoCloseOnShiftZero){
		   TradeX.PositionCloseCustom(_Symbol,MagicNumber, Slippage );
		}
		
		
		// Open buy order
		if(upSignal[1] > 0 /*TotalTrades*/)
		{  
		   //--Getting Fib Levels
		   double fib_range = Price.GetFibLevels(sellTailP, buyTailP,  upSignalP, downSignalP, "BUY");
		   
		   
		   double fib_261_8 = Trade.NormalizePrice(sellTailP + (fib_range*2.618));
		   double fib_200_0 = Trade.NormalizePrice(sellTailP + (fib_range*2.000));
		   double fib_161_8 = Trade.NormalizePrice(sellTailP + (fib_range*1.618));
		   //printf("buy_fib_161_8");
		   //printf(fib_161_8);
		   double fib_080_0 = Trade.NormalizePrice(sellTailP + (fib_range*0.800));
		   double fib_061_8 = Trade.NormalizePrice(sellTailP + (fib_range*0.618));
		   printf(fib_061_8);
		   double fib_050_0 = Trade.NormalizePrice(sellTailP + (fib_range*0.500));
		   printf(fib_050_0);
		   double fib_038_2 = Trade.NormalizePrice(sellTailP + (fib_range*0.382));
		   double fib_023_6 = Trade.NormalizePrice(sellTailP + (fib_range*0.236));
		   
		   //Make them dynamic
		   double profitFibLevel = 0.0;
		   if(UseFibProfitLevel) profitFibLevel = fib_161_8;
		   double lossFibLevel = 0.0;
		   if(AutoStopLossSet) lossFibLevel = fib_023_6;
		   
		   //Close Orders
		   //Trade.Close(_Symbol);
		   //TradeX.PositionClose(_Symbol, Slippage );
		   TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
		    
		   //Place order
		   if(PlaceTrades && PositionType() != POSITION_TYPE_BUY && glBuyPlaced == false && TotalTrades > PositionsTotal())
			   glBuyPlaced = Trade.Buy(_Symbol,tradeSize, 0.000000, 0.000000, EA_Version+"["+MagicNumber+"]:"+Price.GetTimeFrame());
			//else {
			string msg = "BUY Price:"+SymbolInfoDouble(_Symbol,SYMBOL_ASK)+"\n"+
			             "LOT:"+tradeSize+"\n"+
			             "SL 1:"+fib_050_0+"\n"+
			             "SL 2:"+fib_061_8+"\n"+
			             "TP 1:"+fib_161_8+"\n"+
			             "TP 2:"+fib_200_0+"\n"+
			             ""+EA_Version+"";
			             
			Price.SendAlert("BUY", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
			printf(msg);
			//};  
		
			if(glBuyPlaced == true)  
			{
				double openPrice = PositionOpenPrice(_Symbol);
				
				double buyStop = BuyStopLoss(_Symbol,StopLoss,lossFibLevel, openPrice);
				if(buyStop > 0) AdjustBelowStopLevel(_Symbol,buyStop);
				
				double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,profitFibLevel,openPrice);
				if(buyProfit > 0) AdjustAboveStopLevel(_Symbol,buyProfit);
				
				if(buyStop > 0 || buyProfit > 0) {
				  //Trade.ModifyPosition(_Symbol,buyStop,buyProfit);
				  Trade.ModifyPositionCustom(_Symbol,MagicNumber,buyStop,buyProfit);
				}
				glSellPlaced = false;
			} 
		}
		
		
		// Open sell order
		if(downSignal[1] > 0 /*TotalTrades*/)
		{
		
		
		 double fib_range =  Price.GetFibLevels(sellTailP, buyTailP,  upSignalP, downSignalP, "SELL");
		  
		   double fib_261_8 = Trade.NormalizePrice(buyTailP - (fib_range*2.618));
		   double fib_200_0 = Trade.NormalizePrice(buyTailP - (fib_range*2.000));
		   double fib_161_8 = Trade.NormalizePrice(buyTailP - (fib_range*1.618));
		   //printf("sell_fib_161_8");
		   //printf(fib_161_8);
		   double fib_080_0 = Trade.NormalizePrice(buyTailP - (fib_range*0.800));
		   double fib_061_8 = Trade.NormalizePrice(buyTailP - (fib_range*0.618));
		   double fib_050_0 = Trade.NormalizePrice(buyTailP - (fib_range*0.500));
		   double fib_038_2 = Trade.NormalizePrice(buyTailP - (fib_range*0.382));
		   double fib_023_6 = Trade.NormalizePrice(buyTailP - (fib_range*0.236));
		   
		   //Make them dynamic
		   double profitFibLevel = 0.0;
		   if(UseFibProfitLevel) profitFibLevel = fib_161_8;
		   double lossFibLevel = 0.0;
		   if(AutoStopLossSet) lossFibLevel = fib_023_6;
		   
		  //Close Orders
		  // Trade.Close(_Symbol);
		  //TradeX.PositionClose(_Symbol, Slippage );
		  TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
		   
		   //Place order
		    if(PlaceTrades && PositionType() != POSITION_TYPE_SELL && glSellPlaced == false && TotalTrades > PositionsTotal())
			   glSellPlaced = Trade.Sell(_Symbol,tradeSize, 0.000000, 0.000000, EA_Version+"["+MagicNumber+"]:"+Price.GetTimeFrame());
			//  else {
			  string msg = "SELL Price:"+SymbolInfoDouble(_Symbol,SYMBOL_BID)+"\n"+
			             "LOT:"+tradeSize+"\n"+
			             "SL 1:"+fib_050_0+"\n"+
			             "SL 2:"+fib_061_8+"\n"+
			             "TP 1:"+fib_161_8+"\n"+
			             "TP 2:"+fib_200_0+"\n"+
			             ""+EA_Version+"";
			             
			  Price.SendAlert("SELL", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
			  printf(msg);
			//}
			
			if(glSellPlaced == true)
			{
				double openPrice = PositionOpenPrice(_Symbol);
				
				double sellStop = SellStopLoss(_Symbol,StopLoss,lossFibLevel, openPrice);
				if(sellStop > 0) sellStop = AdjustAboveStopLevel(_Symbol,sellStop);
				
				double sellProfit = SellTakeProfit(_Symbol,TakeProfit,profitFibLevel, openPrice);
				if(sellProfit > 0) sellProfit = AdjustBelowStopLevel(_Symbol,sellProfit);
				
				if(sellStop > 0 || sellProfit > 0) {
				   //Trade.ModifyPosition(_Symbol,sellStop,sellProfit);
				   Trade.ModifyPositionCustom(_Symbol,MagicNumber,sellStop,sellProfit);
				}
				glBuyPlaced = false;
			} 
		}
		
	} // Order placement end
	
	
	// Break even
	if(UseBreakEven == true && PositionType(_Symbol) != -1)
	{
		Trail.BreakEven(_Symbol,BreakEvenProfit,LockProfit);
	}
	
	
	// Trailing stop
	if(UseTrailingStop == true && PositionType(_Symbol) != -1)
	{
		Trail.TrailingStop(_Symbol,TrailingStop,MinimumProfit,Step);
	}


//References
//https://www.mql5.com/en/docs/constants/structures/mqltraderequest/
//https://www.mql5.com/en/code/32980

//https://www.mql5.com/en/market/product/58067?source=External%3Ahttps%3A%2F%2Fwww.google.com%2F#description

   

}


