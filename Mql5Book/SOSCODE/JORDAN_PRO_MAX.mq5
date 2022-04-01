#property copyright "Source Code Technlogies"
#property link      "https://www.soscode.com:3MA"
#property version   "1.00:2022.03.24@15:19"

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


input bool PlaceTradesInPut = true;
input int MyMagicNumber = 0;
input int MAPeriodShort=10;
input int MAPeriodMedium=20;
input int MAPeriodLong=34;
//input int FourMAPeriod=200;
//input bool useOnlyNonlag = false;
//input bool confirmByNonlag = true;
//input int NonLagMAPeriod=200;
input int MAShift=0;
input ENUM_MA_METHOD MAMethodS= MODE_EMA;
input ENUM_MA_METHOD MAMethodM= MODE_EMA;
input ENUM_MA_METHOD MAMethodL= MODE_EMA;
input ENUM_APPLIED_PRICE MAPrice= PRICE_CLOSE;

sinput string MoneyManagement;		
input double volume=0.1;

sinput string CashMeasures;

input bool UseTakeProfitCash=false;
input double takeProfitCash=10.0;
input double DailyProfitCash=100.0;
input double lossToStopDayTrading=50.0;
//input double stopLossCash=0.0;

sinput string PercentageMeasures;

input bool UseTakeProfitPercentage=true;
input double takeProfitPercentage=6.0;
input double DailyProfitPercentage=20;
input double PercentagelossToStopDayTrading = 20;
//input double stopLossPercentage=0.0;

input bool AllSymbols = false;
input bool TradeOnEveryTick = false;
input int MaximumTradeCount = 2;
input int TotalAccMaximumTradeCount = 6;
//input bool MiniExit = false;//pend

sinput string TradeTypeOptions;	
input bool FullAutoPilot = true;
input bool SellOnly = false;
input bool BuyOnly = false;

sinput string ALERTS;		
input bool   alertsOnCurrent = true;
input bool   alertsMessage   = true;
input bool   alertsOnPhone   = true;
input bool   alertsEmail     = false;
input bool   alertsSound     = false;
input bool   alertsTelegram  = false;
input string     APIkey      = "1819898948:AAFRCYc45DMt_hTjwRtUuk58iRIvc1bRcIs";
input string     Channel_ID  = "-590157620";
//-------------------------


enum orderType{
   orderBuy,
   orderSell
};

datetime candleTimes[],lastCandleTime;
string CurSignal="NONE";
string CurTrend = "NONE";
int CandleSeq=1;
long MagicNumber=0;
double onStartEquity=0;
bool innerlocked = true;
//+---trade closing
int RTOTAL=4;       
int SLEEPTIME=1;     
int  Deviation_=10;
long Slippage = 3;
double curProfit=0;
bool buyPlaced = false;
bool sellPlaced = false;
bool PlaceTrades = true;
double tradeSize;
string EA_Version = "#Jordan_PRO_MAX EA-V1.00";

MqlTradeRequest request;
MqlTradeResult result;
MqlTradeCheckResult checkResult;

//+------------------------------------------------------------------+ 
//| start function                                                   |
//+------------------------------------------------------------------+
int OnInit(){
	ArraySetAsSeries(candleTimes,true);
	onStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
	PlaceTrades = PlaceTradesInPut;
	return(0);
}



void OnTick(){
	curProfit = NormalizeDouble((AccountInfoDouble(ACCOUNT_EQUITY) - onStartEquity),_Digits); 
//Comment("Copyright © 2022 Soscode Tech,\nStart Bal. "+onStartEquity+" , Current Bal. "+AccountInfoDouble(ACCOUNT_EQUITY));
Comment("Copyright © 2022 Soscode Tech,\nStart Bal. "+onStartEquity+" , Current Bal. "+AccountInfoDouble(ACCOUNT_EQUITY) +", Profit. "+curProfit+"\nSIGNAL: "+CurTrend+"\nInner Locked: "+innerlocked+"\nPlace Trades: "+PlaceTrades);

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
  
	
	if(checkNewCandle(candleTimes,lastCandleTime)){
		// Money management
		//if(UseMoneyManagement == true)  tradeSize = MoneyManagement(_Symbol,volume,RiskPercent,StopLoss);
		//else tradeSize = VerifyVolume(_Symbol,volume);
		tradeSize = volume;
		
		double maS[];
		double maM[];//medium
		double maL[];
		//double NonLagSignalValues[];
		ArraySetAsSeries(maS,true);
		ArraySetAsSeries(maM,true);
		ArraySetAsSeries(maL,true);
		double candleClose[];
		ArraySetAsSeries(candleClose,true);
		int maSHandle= iMA(_Symbol,_Period,MAPeriodShort,MAShift,MAMethodS,MAPrice);
		int maMHandle= iMA(_Symbol,_Period,MAPeriodMedium,MAShift,MAMethodM,MAPrice);
		int maLHandle= iMA(_Symbol,_Period,MAPeriodLong,MAShift,MAMethodL,MAPrice);
		//int NonLagSignalValues = iCustom(_Symbol,_Period, "NonLagMaAlerts");
		
		CopyBuffer(maSHandle,0,0,3,maS);
		CopyBuffer(maMHandle,0,0,3,maM);
		CopyBuffer(maLHandle,0,0,3,maL);//CopyBuffer(NonlagMaHandle,0,0,3,NonLagSignalValues);
		//CopyBuffer(maLHandle,2,0,3,NonLagSignalValues);
		
		
		CopyClose(_Symbol,_Period,0,3,candleClose);
	
		
		//Unlocking EA
		/*if(CurSignal == "NONE"){
		 //do actuals on when to start trading
		}*/

		if((maS[CandleSeq] > maM[CandleSeq])&&(maS[CandleSeq]>maL[CandleSeq])){//*** BUYING HERE
			//cross up
			//Print("Cross above!");
			//if previous was a sell
			if(CurSignal == "SELL"){
			   Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
			   innerlocked = false;
			}
			//closePosition();
			CloseAllTrades("SELL"); 
      	//TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage);
			//makePosition(orderBuy);
			CurSignal="BUY";
			CurTrend="BUYING";
			

		}else if((maS[CandleSeq]<maM[CandleSeq])&&(maS[CandleSeq]<maL[CandleSeq])){//*** SELLING HERE
			//cross down
			//Print("Cross under!");
			//if previous was a buy
			if(CurSignal == "BUY"){
			   Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
			   innerlocked = false;  
			}
			//closePosition();
			CloseAllTrades("BUY");
   		//TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage);
			//makePosition(orderSell); 
			CurSignal="SELL"; 
			CurTrend="SELLING"; 
			

		}else{
			//trailing

		}
		 
		
      //Check Daily Target
	   CheckDailyTarget();
	}
	
	if(NewBar.CheckNewBar(_Symbol,_Period) && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades && !innerlocked){
	 if(CurSignal=="BUY" && !buyPlaced){
	      //Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
		    if(FullAutoPilot)
		      makePosition(orderBuy);
		     else if(BuyOnly) 
		      makePosition(orderBuy);
		 }
		 if(CurSignal=="SELL" && !sellPlaced){
		   //Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
		   if(FullAutoPilot)
   		   makePosition(orderSell);
   		  else if(SellOnly) 
   		   makePosition(orderSell);
		 }
	}
	else if(TradeOnEveryTick && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades && !innerlocked){
	 if(CurSignal=="BUY" && !buyPlaced){
	      //Price.SendAlert("BUY", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
		    if(FullAutoPilot)
		      makePosition(orderBuy);
		     else if(BuyOnly) 
		      makePosition(orderBuy);
		 }
		 if(CurSignal=="SELL" && !sellPlaced){
		 //Price.SendAlert("SELL", "\n "+EA_Version+" ", alertsMessage, alertsOnPhone, alertsEmail, alertsSound, alertsTelegram, Channel_ID, APIkey);
		   if(FullAutoPilot)
   		   makePosition(orderSell);
   		  else if(SellOnly) 
   		   makePosition(orderSell);
		 }
	}
	
	//### By Cash ###########
	if(UseTakeProfitCash){
	//profits
   	if(TotalProfit() >=takeProfitCash){
         	   if(!AllSymbols){
                  TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
                }
                else{
                    TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );      
                }
        }
  //losses
     if(TotalProfit() < -(lossToStopDayTrading)){
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
   	if(TotalProfit() >= ((takeProfitPercentage/100) * onStartEquity)){
   	   if(!AllSymbols){
            TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
          }
          else{
              CloseAllTrades();      
          }
   	}
   	//losses
     if(TotalProfit() < -((PercentagelossToStopDayTrading/100) * onStartEquity)){
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
bool CheckDailyTarget(){
   double curTodayprofit = AccountInfoDouble(ACCOUNT_EQUITY) - onStartEquity;
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
   	}else{
   		 //Print("Not Checked! ERROR :"+IntegerToString(checkResult.retcode));
   		 Print(__FUNCTION__,"():Not Checked! ERROR : ",ResultRetcodeDescription(checkResult.retcode));
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

   double MaxLot,volume,Bid;
//---- получение данных для расчёта    
   if(!PositionGetDouble(POSITION_VOLUME,volume)) return(true);
   if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX,MaxLot)) return(true);
   if(!SymbolInfoDouble(symbol,SYMBOL_BID,Bid)) return(true);

//---- проверка лота на максимальное допустимое значение       
   if(volume>MaxLot) volume=MaxLot;

//---- Инициализация структуры торгового запроса MqlTradeRequest для закрывания BUY позиции
   request.type   = ORDER_TYPE_SELL;
   request.price  = Bid;
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = volume;
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

   double MaxLot,volume,Ask;
//---- получение данных для расчёта    
   if(!PositionGetDouble(POSITION_VOLUME,volume)) return(true);
   if(!SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX,MaxLot)) return(true);
   if(!SymbolInfoDouble(symbol,SYMBOL_ASK,Ask)) return(true);

//---- проверка лота на максимальное допустимое значение       
   if(volume>MaxLot) volume=MaxLot;

//---- Инициализация структуры торгового запроса MqlTradeRequest для закрывания SELL позиции
   request.type   = ORDER_TYPE_BUY;
   request.price  = Ask;
   request.action = TRADE_ACTION_DEAL;
   request.symbol = symbol;
   request.volume = volume;
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
//+------------------------------------------------------------------+

   

