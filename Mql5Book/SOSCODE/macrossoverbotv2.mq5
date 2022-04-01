#property copyright "Source Code Technlogies"
#property link      "https://www.soscode.com"
#property version   "1.00"

#include <Trade\XTrade.mqh>
//#include <Mql5Book\XTrade.mqh>
CTrade TradeX;


input bool PlaceTrades = true;
input int MyMagicNumber = 0;
input int MAPeriodShort=2;
input int MAPeriodLong=200;
input int FourMAPeriod=200;
input bool useOnlyNonlag = false;
input bool confirmByNonlag = true;
input int NonLagMAPeriod=200;
input int MAShift=0;
input ENUM_MA_METHOD MAMethodS= MODE_EMA;
input ENUM_MA_METHOD MAMethodL= MODE_EMA;
input ENUM_APPLIED_PRICE MAPrice= PRICE_CLOSE;

sinput string MoneyManagement;		
input double volume=0.2;
input double takeProfitPercentage=1.0;
input double DailyProfitPercentage=20;
input double stopLossPercentage=0.0;
input double PercentagelossToStopDayTrading = 50;
input bool AllSymbols = false;
input bool TradeOnEveryTick = true;
input int MaximumTradeCount = 1000;
input bool miniexitByNonlag = true;

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
input bool   alertsTelegram  = true;
input string     APIkey      = "1819898948:AAFRCYc45DMt_hTjwRtUuk58iRIvc1bRcIs";
input string     Channel_ID  = "-590157620";
//-------------------------


enum orderType{
   orderBuy,
   orderSell
};

datetime candleTimes[],lastCandleTime;
string CurSignal="BUY";
string CurTrend;
int CandleSeq=1;
int MagicNumber=0;
double onStartEquity=0;
bool innerlocked = true;
//+---trade closing
int RTOTAL=4;       
int SLEEPTIME=1;     
int  Deviation_=10;
long Slippage = 3;


MqlTradeRequest request;
MqlTradeResult result;
MqlTradeCheckResult checkResult;

//+------------------------------------------------------------------+ 
//| start function                                                   |
//+------------------------------------------------------------------+
int OnInit(){
	ArraySetAsSeries(candleTimes,true);
	onStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
	return(0);
}



void OnTick(){
Comment("Copyright © 2021 Soscode Tech,\nStart Bal. "+onStartEquity+" , Current Bal. "+AccountInfoDouble(ACCOUNT_EQUITY));

// rechecking if magic number is set
   if(MagicNumber <= 0 && MyMagicNumber <= 0)
     {
      MagicNumber = ChartID();
      printf("MagicNumber AutoSet To => "+ MagicNumber);
     }else if(MyMagicNumber > 0){
      MagicNumber = MyMagicNumber;
     }
  
	
	if(checkNewCandle(candleTimes,lastCandleTime)){
		double maS[];
		double maL[];
		double NonLagSignalValues[];
		ArraySetAsSeries(maS,true);
		ArraySetAsSeries(maL,true);
		double candleClose[];
		ArraySetAsSeries(candleClose,true);
		int maSHandle= iMA(_Symbol,_Period,MAPeriodShort,MAShift,MAMethodS,MAPrice);
		int maLHandle= iMA(_Symbol,_Period,MAPeriodLong,MAShift,MAMethodL,MAPrice);
		//int maLHandle = iCustom(_Symbol,_Period, "NonLagMaAlerts");
		
		CopyBuffer(maSHandle,0,0,3,maS);
		CopyBuffer(maLHandle,0,0,3,maL);//CopyBuffer(NonlagMaHandle,0,0,3,NonLagSignalValues);
		CopyBuffer(maLHandle,2,0,3,NonLagSignalValues);
		
		
		CopyClose(_Symbol,_Period,0,3,candleClose);
		
		/*Print("nonlag trend vvv");
		Print(NonLagSignalValues[0]);
		Print("nonlag vvv");
		Print(maL[1]);
		Print("ma vvv");
		Print(maS[1]);*/

		if((maS[CandleSeq+1] < maL[CandleSeq+1])&&(maS[CandleSeq]>maL[CandleSeq])){
			//cross up
			Print("Cross above!");
			//closePosition();
			CloseAllTrades(); 
			//makePosition(orderBuy);
			CurSignal="BUY";
			innerlocked = false;

		}else if((maS[CandleSeq+1]>maL[CandleSeq+1])&&(maS[CandleSeq]<maL[CandleSeq])){
			//cross down
			Print("Cross under!");
			//closePosition();
			CloseAllTrades();
			//makePosition(orderSell); 
			CurSignal="SELL";  
			innerlocked = false;  

		}else{
			//trailing

		}
		 
		
	}
	
	if(checkNewCandle(candleTimes,lastCandleTime) && MaximumTradeCount > PositionsTotal() && PlaceTrades && !innerlocked){
	 if(CurSignal=="BUY"){
		   makePosition(orderBuy);
		 }
		 if(CurSignal=="SELL"){
		   makePosition(orderSell);
		 }
	}
	else if(TradeOnEveryTick && MaximumTradeCount > PositionsTotal() && PlaceTrades && !innerlocked){
	 if(CurSignal=="BUY"){
		   makePosition(orderBuy);
		 }
		 if(CurSignal=="SELL"){
		   makePosition(orderSell);
		 }
	}
	
	//Taking Profits
	if(TotalProfit() >= ((takeProfitPercentage/100) * onStartEquity)){
	   if(!AllSymbols){
         TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
       }
       else{
           CloseAllTrades();      
       }
	}
	//close by lose
  if(TotalProfit() < -((PercentagelossToStopDayTrading/100) * onStartEquity)){
	   if(!AllSymbols){
         TradeX.PositionCloseCustom(_Symbol,MagicNumber ,Slippage );
         //PlaceTrades= false;
         //send notification
         //Stop auto trading
       }
       else{
           CloseAllTrades();      
       }
	}
}

bool makePosition(orderType type){
	ZeroMemory(request);
	request.symbol=_Symbol;
	request.volume=volume;
	request.action=TRADE_ACTION_DEAL;
	request.type_filling=ORDER_FILLING_FOK;
	double price=0;

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
		Print("Not Checked! ERROR :"+IntegerToString(checkResult.retcode));
		return false;
	}

	if(OrderSend(request,result)){
		Print("Ordem enviada com sucesso!");
	}else{
		Print("Ordem não enviada!");
		return false;
	}

	if(result.retcode==TRADE_RETCODE_DONE || result.retcode==TRADE_RETCODE_PLACED){
		Print("Trade Placed!");
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
      Print(__FUNCTION__,"(): Неверные данные для структуры торгового запроса!");
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
      Print(__FUNCTION__,"(): Невозможно закрыть позицию!");
      Print(__FUNCTION__,"(): OrderSend(): ",ResultRetcodeDescription(result.retcode));
      return(false);
     }
   else
   if(result.retcode==TRADE_RETCODE_DONE)
     {
      Signal=false;
      comment="";
      StringConcatenate(comment,"<<< ============ ",__FUNCTION__,"(): Buy позиция по ",symbol," закрыта ============ >>>");
      Print(comment);
      PlaySound("ok.wav");
     }
   else
     {
      Print(__FUNCTION__,"(): Невозможно закрыть позицию!");
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
      Print(__FUNCTION__,"(): Неверные данные для структуры торгового запроса!");
      Print(__FUNCTION__,"(): OrderCheck(): ",ResultRetcodeDescription(check.retcode));
      return(false);
     }
//----    
   string comment="";
   StringConcatenate(comment,"<<< ============ ",__FUNCTION__,"(): Закрываем Sell позицию по ",symbol," ============ >>>");
   Print(comment);

//---- Отправка приказа на закрывание позиции на торговый сервер
   if(!OrderSend(request,result) || result.retcode!=TRADE_RETCODE_DONE)
     {
      Print(__FUNCTION__,"(): Невозможно закрыть позицию!");
      Print(__FUNCTION__,"(): OrderSend(): ",ResultRetcodeDescription(result.retcode));
      return(false);
     }
   else
   if(result.retcode==TRADE_RETCODE_DONE)
     {
      Signal=false;
      comment="";
      StringConcatenate(comment,"<<< ============ ",__FUNCTION__,"(): Sell позиция по ",symbol," закрыта ============ >>>");
      Print(comment);
      PlaySound("ok.wav");
     }
   else
     {
      Print(__FUNCTION__,"(): Невозможно закрыть позицию!");
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
      case TRADE_RETCODE_REQUOTE: str="Реквота"; break;
      case TRADE_RETCODE_REJECT: str="Запрос отвергнут"; break;
      case TRADE_RETCODE_CANCEL: str="Запрос отменен трейдером"; break;
      case TRADE_RETCODE_PLACED: str="Ордер размещен"; break;
      case TRADE_RETCODE_DONE: str="Заявка выполнена"; break;
      case TRADE_RETCODE_DONE_PARTIAL: str="Заявка выполнена частично"; break;
      case TRADE_RETCODE_ERROR: str="Ошибка обработки запроса"; break;
      case TRADE_RETCODE_TIMEOUT: str="Запрос отменен по истечению времени";break;
      case TRADE_RETCODE_INVALID: str="Неправильный запрос"; break;
      case TRADE_RETCODE_INVALID_VOLUME: str="Неправильный объем в запросе"; break;
      case TRADE_RETCODE_INVALID_PRICE: str="Неправильная цена в запросе"; break;
      case TRADE_RETCODE_INVALID_STOPS: str="Неправильные стопы в запросе"; break;
      case TRADE_RETCODE_TRADE_DISABLED: str="Торговля запрещена"; break;
      case TRADE_RETCODE_MARKET_CLOSED: str="Рынок закрыт"; break;
      case TRADE_RETCODE_NO_MONEY: str="Нет достаточных денежных средств для выполнения запроса"; break;
      case TRADE_RETCODE_PRICE_CHANGED: str="Цены изменились"; break;
      case TRADE_RETCODE_PRICE_OFF: str="Отсутствуют котировки для обработки запроса"; break;
      case TRADE_RETCODE_INVALID_EXPIRATION: str="Неверная дата истечения ордера в запросе"; break;
      case TRADE_RETCODE_ORDER_CHANGED: str="Состояние ордера изменилось"; break;
      case TRADE_RETCODE_TOO_MANY_REQUESTS: str="Слишком частые запросы"; break;
      case TRADE_RETCODE_NO_CHANGES: str="В запросе нет изменений"; break;
      case TRADE_RETCODE_SERVER_DISABLES_AT: str="Автотрейдинг запрещен сервером"; break;
      case TRADE_RETCODE_CLIENT_DISABLES_AT: str="Автотрейдинг запрещен клиентским терминалом"; break;
      case TRADE_RETCODE_LOCKED: str="Запрос заблокирован для обработки"; break;
      case TRADE_RETCODE_FROZEN: str="Ордер или позиция заморожены"; break;
      case TRADE_RETCODE_INVALID_FILL: str="Указан неподдерживаемый тип исполнения ордера по остатку "; break;
      case TRADE_RETCODE_CONNECTION: str="Нет соединения с торговым сервером"; break;
      case TRADE_RETCODE_ONLY_REAL: str="Операция разрешена только для реальных счетов"; break;
      case TRADE_RETCODE_LIMIT_ORDERS: str="Достигнут лимит на количество отложенных ордеров"; break;
      case TRADE_RETCODE_LIMIT_VOLUME: str="Достигнут лимит на объем ордеров и позиций для данного символа"; break;
      case TRADE_RETCODE_INVALID_ORDER: str="Неверный или запрещённый тип ордера"; break;
      case TRADE_RETCODE_POSITION_CLOSED: str="Позиция с указанным POSITION_IDENTIFIER уже закрыта"; break;
      default: str="Неизвестный результат";
     }
//----
   return(str);
  }
//+------------------------------------------------------------------+

   

