//+------------------------------------------------------------------+
//|                                 Bands/RSI CounterTrend (Hedging) |
//|                                                     Andrew Young |
//|                                 http://www.expertadvisorbook.com |
//+------------------------------------------------------------------+

#property copyright "Jordan Capital Inc."
#property link      "https://www.jordancapital.com"
#property version   "2023.04.03@11:30"
#property description "A counter-trend trading system using Bollinger Bands and RSI for hedging accounts: Boom and Crash"

/*
 Creative Commons Attribution-NonCommercial 3.0 Unported
 http://creativecommons.org/licenses/by-nc/3.0/

 You may use this file in your own personal projects. You
 may modify it if necessary. You may even share it, provided
 the copyright above is present. No commercial use permitted. 
*/
//to Dos ********************
//Add double confirmation by RSI 30-70
//Restrict to be used only on crash and boom, 5-Minutes

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
CiBollinger Bands;
CiRSI RSI;


//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
input bool PlaceTradesInPut = true;
input ulong MyMagicNumber = 0;
input bool TradeOnNewBar = true;

sinput string MM; 	// Money Management
input bool UseMoneyManagement = false;
input double RiskPercent = 2;
input double FixedVolume = 0.2;
input ulong Slippage = 3;
input double AllowedPriceGap = 0.0;	

sinput string SL; 	
input int StopLoss = 0;
input int TakeProfit = 0;

sinput string TS;		// Trailing Stop
input bool UseTrailingStop = false;
input int TrailingStop = 0;
input int MinimumProfit = 0;
input int Step = 0; 

sinput string BE;		// Break Even
input bool UseBreakEven = false;
input int BreakEvenProfit = 0;
input int LockProfit = 0;
input bool useSteadyProgressRecover = true;
sinput string CashMeasures;
input bool UseTakeProfitCash=true;
input double takeProfitCash_=5.0;
input double takeLossCash=2.0;
input double DailyProfitCash=100.0;
input double lossToStopDayTrading=15.0;

sinput string PercentageMeasures;
input bool UseTakeProfitPercentage=false;
input double takeProfitPercentage=6.0;
input double takeLossPercentage=2.0;
input double DailyProfitPercentage=50;
input double PercentagelossToStopDayTrading = 10;

sinput string BB;		// Bollinger Bands
input int BandsPeriod = 20;
input int BandsShift = 0;
input double BandsDeviation = 2;
input ENUM_APPLIED_PRICE BandsPrice = PRICE_CLOSE; 

sinput string RS;	// RSI
input int RSIPeriod = 14;
input ENUM_APPLIED_PRICE RSIPrice = PRICE_CLOSE;
input int RSISellLevelDefault = 70;
input int RSIBuyLevelDefault = 30;
input bool UseBoomCrashLevels = false;
input int RSISellLevelBoom = 72;
input int RSIBuyLevelBoom = 28;
input int RSISellLevelCrash = 70;
input int RSIBuyLevelCrash = 25;


sinput string Orders; 	
input bool SingleOrderType = false;
input bool doSells_ = true;
input bool doBuys_ = true;
input bool AllSymbols = false;
input bool TradeOnEveryTick = false;
input int MaximumTradeCount = 1;
input int TotalAccMaximumTradeCount = 6;
input int TradeBasketsPerTrend = 1;

sinput string ALERTS;		
input bool   alertsOnCurrent = false;
input bool   alertsOnlyTrendChg = true;
input bool   alertsMessage   = false;
input bool   alertsOnPhone   = true;
input bool   alertsEmail     = false;
input bool   alertsSound     = false;
input bool   alertsTelegram  = false;
input bool   alertsMiniSignals  = false;
input string     APIkey      = "1819898948:AAFRCYc45DMt_hTjwRtUuk58iRIvc1bRcIs";
input string     Channel_ID  = "-1001860762374";

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
string EA_Version = "#JC.CT.v1";
ulong glBuyTicket, glSellTicket;

enum Signal_Actual
{
	SIGNAL_BUY,
	SIGNAL_SELL,
	SIGNAL_NONE,
};

Signal_Actual glSignal;

int RSISellLevel=RSISellLevelDefault;
int RSIBuyLevel=RSIBuyLevelDefault;
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

string trendSignal ="None";

//+---trade closing
int RTOTAL=4;       
int SLEEPTIME=1;     
int  Deviation_=10;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
{
	Bands.Init(_Symbol,_Period,BandsPeriod,BandsShift,BandsDeviation,BandsPrice);
	RSI.Init(_Symbol,_Period,RSIPeriod,RSIPrice);
	
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
     
     if(_Symbol == "Crash 1000 Index" || _Symbol == "Crash 500 Index" || _Symbol == "Crash 1000 Index"){
         if(SingleOrderType){
            doSells = false;
            doBuys = true;
         }else{
            doSells = doSells_;
            doBuys = doBuys_;
         }
         if(UseBoomCrashLevels){
          RSISellLevel = RSISellLevelCrash;
          RSIBuyLevel = RSIBuyLevelCrash;
         }else{
           RSISellLevel = RSISellLevelDefault;
           RSIBuyLevel = RSIBuyLevelDefault;
         }
        
     }
     
     else if(_Symbol == "Boom 1000 Index" || _Symbol == "Boom 500 Index" || _Symbol == "Boom 300 Index"){
         if(SingleOrderType){
            doSells = true;
            doBuys = false;
         }else{
            doSells = true;
            doBuys = true;
         }
         if(UseBoomCrashLevels){
            RSISellLevel = RSISellLevelBoom;
            RSIBuyLevel = RSIBuyLevelBoom;
         }else{
           RSISellLevel = RSISellLevelDefault;
           RSIBuyLevel = RSIBuyLevelDefault;
         }
     }else{
            doSells = doSells_;
            doBuys = doBuys_;
            
            RSISellLevel = RSISellLevelDefault;
            RSIBuyLevel = RSIBuyLevelDefault;
     }
     
      onStartEquity = AccountInfoDouble(ACCOUNT_BALANCE);
	   innerlocked = false;
   	PlaceTrades = PlaceTradesInPut;
      startTime =TimeLocal();

      if(highestBalCaptured == 0.0){
            highestBalCaptured = AccountInfoDouble(ACCOUNT_BALANCE);
        }
	
   return(0);
}



//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
{

    double point = SymbolInfoDouble(_Symbol,SYMBOL_POINT);
    double StopLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   //Calculate Profits
   currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   curBal = AccountInfoDouble(ACCOUNT_BALANCE);
   
   curProfit = NormalizeDouble((currentEquity - onStartEquity),_Digits);
   curBalProfit = NormalizeDouble((curBal - onStartEquity),_Digits);
   
   Comment("Copyright © 2023 Jordan Capital Inc. ["+MagicNumber+"], Loaded @ "+startTime+",\nStart Bal. "+onStartEquity+" Cur Bal. "+curBal+" Bal Profit. "+curBalProfit+" Peak Bal. "+highestBalCaptured+"\nCur EQt. "+ currentEquity +", Flt Profit. "+curProfit+"\nTrade Target: "+ takeProfitCash +", Loss: "+takeLossCash+"\nDaily;- Target: "+ DailyProfitCash +", Loss: "+lossToStopDayTrading+"\nTarget by :Points --\n\n"+
       "SYS-1: RSI ["+RSISellLevelDefault+"-"+RSIBuyLevelDefault+"] (Active) \nSingleOrderType: "+SingleOrderType+ "\n\n"+
       "Trend : "+trendSignal+", Filter: -- \nInner Locked: "+innerlocked+"\nPlace Trades: "+PlaceTrades+"\nPrice Gap: "+CurrentPriceGapRange+" (Allowed - "+AllowedPriceGap+")\n"+lastError);


	// Check for new bar
	bool newBar = true;
	int barShift = 0;
	if(TradeOnNewBar == true) 
	{
		newBar = NewBar.CheckNewBar(_Symbol,_Period);
		barShift = 1;
	}
	
	
	// Timer
	bool timerOn = true;
	if(UseTimer == true)
	{
		timerOn = Timer.DailyTimer(StartHour,StartMinute,EndHour,EndMinute,UseLocalTime);
	}
	
	
	// Update prices
	Bar.Update(_Symbol,_Period);
	
	
	// Order placement
	if(newBar == true /* && timerOn == true*/)
	{ //CHECK MONEY MANAGEMENT
	   if(useSteadyProgressRecover){//recover any drawdown even in positive
         if(highestBalCaptured == 0.0){
               highestBalCaptured = curBal;
         }else if(curBal > highestBalCaptured ){
            highestBalCaptured = curBal;
         }
         //if cur bal goes below highest covered
         if(curBal < highestBalCaptured){
            double new_adv_target = MathAbs(highestBalCaptured - curBal);
             takeProfitCash = takeProfitCash_ + MathAbs(new_adv_target);
             //if(!StaticFibo)UseFibProfitLevel = false;//switch off fib target
         }else{//if curbal is above highBalCaptured or equal, go back to original targets
             takeProfitCash = takeProfitCash_;
             //if(!StaticFibo)UseFibProfitLevel = true;//switch on fib target
         }
      
     }
		
		// Money management
		double tradeSize;
		if(UseMoneyManagement == true) tradeSize = MoneyManagement(_Symbol,FixedVolume,RiskPercent,StopLoss);
		else tradeSize = VerifyVolume(_Symbol,FixedVolume);
		
		
		// Open positions
		ulong buyTickets[], sellTickets[];
		Positions.GetBuyTickets(MagicNumber, buyTickets);
		glBuyTicket = buyTickets[0];
		
		Positions.GetSellTickets(MagicNumber, sellTickets);
		glSellTicket = sellTickets[0];
		
		
		// Trade signal
		//buys
		if(/*Bar.Close(barShift) > Bands.Lower(barShift) &&*/ RSI.Main(2) < RSISellLevel && RSI.Main(1) > RSISellLevel ) {
		    if(doBuys){
	         glSignal = SIGNAL_BUY;
	         
	         
	         //setting signals
   	        int n_candles = 5;
   	        double lowestP = Price.LowestLow(_Symbol,PERIOD_CURRENT,n_candles,0);
   	        lowestP = Trade.NormalizePrice(lowestP);
   	        
   	        double buyStop = BuyStopLoss(_Symbol,StopLoss,0.0,0);
   			  double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,0.0,0);
   			  double buyProfit_2 = 0.0;
   			  double sl_1 = 0.0;
   			  double sl_2 = 0.0;
   			  if(lowestP < buyStop){
      			  sl_1 = lowestP;
      			  sl_2 = buyStop; 
   			  }else{
   			     sl_1 = buyStop;
      			  sl_2 = lowestP; 
   			  }
   				
   			  string msg = "\n%F0%9F%94%BC[BUY Price:"+SymbolInfoDouble(_Symbol,SYMBOL_BID)+"] \n"+
   			             "%F0%9F%92%B0[LOT : "+tradeSize+"] \n"+
   			             "%F0%9F%9B%91[SL: "+sl_1+"] \n"+
   			             "%F0%9F%9B%91[SL: "+sl_2+"] \n"+
   			             "%E2%9C%85[TP-1: "+buyProfit+"] \n"+
   			             "%E2%9C%85[TP-2: "+buyProfit_2+"] \n\n"+
   			             ""+EA_Version+""; 
   			              
   			   if(alertsOnlyTrendChg){
   			      if(trendSignal == "SELL"){//was from sell going to buy
   			         Price.SendAlert("BUY", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
   			      }
   			   } else{
   			      Price.SendAlert("BUY", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
   			   }   
   	         
            	trendSignal = "BUY";
            	//setting signals ends here	
	      }else{
	         glSignal = SIGNAL_NONE;
	      }
		
		}
		
		//sells
	   if(/*Bar.Close(barShift) < Bands.Upper(barShift) && */RSI.Main(2) > RSIBuyLevel && RSI.Main(1) < RSIBuyLevel) {
	   
	      if(doSells){
	         glSignal = SIGNAL_SELL;
	         
	         
	        //setting signals
	        int n_candles = 5;
	        double highestP = Price.HighestHigh(_Symbol,PERIOD_CURRENT,n_candles,0);
	        highestP = Trade.NormalizePrice(highestP);
	        
	        
			  double sellStop = SellStopLoss(_Symbol,StopLoss,0.0,0);
			  double sellProfit = SellTakeProfit(_Symbol,TakeProfit,0.0,0);
			  double sellProfit_2 = 0.0;
			  double sl_1 = 0.0;
			  double sl_2 = 0.0;
			  if(highestP > sellStop){
   			  sl_1 = highestP;
   			  sl_2 = sellStop; 
			  }else{
			     sl_1 = sellStop;
   			  sl_2 = highestP; 
			  }
				
			  string msg = "\n%F0%9F%94%BD[SELL Price:"+SymbolInfoDouble(_Symbol,SYMBOL_BID)+"] \n"+
			             "%F0%9F%92%B0[LOT : "+tradeSize+"] \n"+
			             "%F0%9F%9B%91[SL: "+sl_1+"] \n"+
			             "%F0%9F%9B%91[SL: "+sl_2+"] \n"+
			             "%E2%9C%85[TP-1: "+sellProfit+"] \n"+
			             "%E2%9C%85[TP-2: "+sellProfit_2+"] \n\n"+
			             ""+EA_Version+"";      

         	   if(alertsOnlyTrendChg){
   			      if(trendSignal == "BUY"){//was from buy going to sell
   			         Price.SendAlert("SELL", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
   			      }
   			   } else{
   			      Price.SendAlert("SELL", msg, alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey); 
   			   }   
   			   trendSignal = "SELL";	
   			   //setting signals ends here	
   	         
	      }else{
	         glSignal = SIGNAL_NONE;
	      }
	      
	      
	   }
		
		
		// Open buy order
		if(glSignal == SIGNAL_BUY /*&& Bar.Close(barShift) > Bands.Lower(barShift) && Bar.Close(barShift+1) <= Bands.Lower(barShift+1)*/ && Positions.Buy(MagicNumber) < TradeBasketsPerTrend) 
		{
			if(glSellTicket > 0)
			{
			   Trade.Close(glSellTicket);
			}
			
			glBuyTicket = Trade.Buy(_Symbol,tradeSize);
		
			if(glBuyTicket > 0)  
			{
				double openPrice = PositionOpenPrice(glBuyTicket);
				
				double buyStop = BuyStopLoss(_Symbol,StopLoss,0.0,openPrice);
				if(buyStop > 0) AdjustBelowStopLevel(_Symbol,buyStop);
				
				double buyProfit = BuyTakeProfit(_Symbol,TakeProfit,0.0,openPrice);
				if(buyProfit > 0) AdjustAboveStopLevel(_Symbol,buyProfit);
				
				if(buyStop > 0 || buyProfit > 0) Trade.ModifyPosition(glBuyTicket,buyStop,buyProfit);
				
				glSignal = SIGNAL_NONE;
			} 
		}
		
		
		// Open sell order
		if(glSignal == SIGNAL_SELL /*&& Bar.Close(barShift) < Bands.Upper(barShift) && Bar.Close(barShift+1) >= Bands.Upper(barShift+1)*/ && Positions.Sell(MagicNumber) < TradeBasketsPerTrend) 
		{
			if(glBuyTicket > 0)
			{
			   Trade.Close(glBuyTicket);
			}
			
			glSellTicket = Trade.Sell(_Symbol,tradeSize);
			
			if(glSellTicket > 0)
			{
				double openPrice = PositionOpenPrice(glSellTicket);
				
				double sellStop = SellStopLoss(_Symbol,StopLoss,0.0,openPrice);
				if(sellStop > 0) sellStop = AdjustAboveStopLevel(_Symbol,sellStop);
				
				double sellProfit = SellTakeProfit(_Symbol,TakeProfit,0.0,openPrice);
				if(sellProfit > 0) sellProfit = AdjustBelowStopLevel(_Symbol,sellProfit);
				
				if(sellStop > 0 || sellProfit > 0) Trade.ModifyPosition(glSellTicket,sellStop,sellProfit);
				
				glSignal = SIGNAL_NONE;
			} 
		}
		//CheckDailyTarget();
		CheckDailyTarget();
		//check profits and losses
		CheckProfits();
		
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
   	if((TotalProfit >=takeProfitCash && (takeProfitCash != 0.0)) || (TotalProfit < -(takeLossCash) && (takeLossCash != 0.0)) ){//check if orders have tp set , it the best way
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
   	if((TotalProfit >= ((takeProfitPercentage/100) * onStartEquity) && (takeProfitPercentage != 0.0)) ||
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
          }
          else{
              CloseAllTrades();      
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

		//if(UseMoneyManagement == true) { tradeSize = MoneyManagement(_Symbol,volume,RiskPercent,stopLossMM_);}
		//else {tradeSize = VerifyVolume(_Symbol,volume);}

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

