//+------------------------------------------------------------------+
//|                                              SignalsBoxSOSv1.mq4 |
//|                                    Copyright 2019, SoSCode Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property strict
#property copyright "Copyright 2019, SoSCode Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include <stdlib.mqh>

//external variables
//+------------------------------------------------------------------
extern bool  AllowPlaceTrades = false;
extern bool  AllowCloseTradesMajor = false;
extern bool  AllowCloseTradesMinor = false;
extern int Slippage = 5;
extern bool  AllowFXNUKESWsignals = true;
extern bool  AllowFXNUKESCsignals = false;
extern bool  AllowFXNUKEDTsignals = false;
extern bool  AllowMinorTrendSignals = true;


//+------------------------------------------------------------------
//My Globals
datetime LastActiontimeDrawLine;
datetime LastActiontimeNotification;
double FXNUKESW_UP;
double FXNUKESW_DN;
double FXNUKESC_UP;
double FXNUKESC_DN;
double FXNUKEDT_UP;
double FXNUKEDT_DN;

double ARROWS_UP;
double ARROWS_DN;

string FXNUKESW_sg;
string FXNUKESC_sg;
string FXNUKEDT_sg;
string ARROWS_sg;
string SignalDataGlobal;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
 
//---generating signal
if(AllowFXNUKESWsignals){
    FXNUKESW_UP = iCustom(NULL, 0, "FXNUKESW", true, true, true, 6,1);
    FXNUKESW_DN = iCustom(NULL, 0, "FXNUKESW", true, true, true, 7,1);
    
       //--swing
     if(FXNUKESW_UP != EMPTY_VALUE && FXNUKESW_UP != 0){
          sendBuySignalMajor("FXNUKESW_UP");
     }
     if(FXNUKESW_DN != EMPTY_VALUE && FXNUKESW_DN != 0){
         sendSellSignalMajor("FXNUKESW_DN");
     }
    }
if(AllowFXNUKESCsignals){
    FXNUKESC_UP = iCustom(NULL, 0, "FXNUKESC", true, true, true, 6,1);
    FXNUKESC_DN = iCustom(NULL, 0, "FXNUKESC", true, true, true, 7,1);
    
      //scalper
     if(FXNUKESC_UP != EMPTY_VALUE && FXNUKESC_UP != 0){
         sendBuySignalMajor("FXNUKESC_UP");
     }
     if(FXNUKESC_DN != EMPTY_VALUE && FXNUKESC_DN != 0){
         sendSellSignalMajor("FXNUKESC_DN");
     }
     
    }
if(AllowFXNUKEDTsignals){
    FXNUKEDT_UP = iCustom(NULL, 0, "FXNUKEDT", true, true, true, 6,1);
    FXNUKEDT_DN = iCustom(NULL, 0, "FXNUKEDT", true, true, true, 7,1);
    
    //day trader
  if(FXNUKEDT_UP != EMPTY_VALUE && FXNUKEDT_UP != 0){
       sendBuySignalMajor("FXNUKEDT_UP");
  }
  if(FXNUKEDT_DN != EMPTY_VALUE && FXNUKEDT_DN != 0){
      sendSellSignalMajor("FXNUKEDT_DN");
  }
    }        
if(AllowMinorTrendSignals){ 
    ARROWS_UP = iCustom(NULL, 0, "ARROWS", 20, 2, 1.0,1,1,1000, 4,1);
    ARROWS_DN = iCustom(NULL, 0, "ARROWS", 20, 2, 1.0,1,1,1000, 5,1);
    
  if(ARROWS_UP != EMPTY_VALUE && ARROWS_UP != 0 && ARROWS_sg == "SELL"){//ARROWS_sg holds previous trend to trig
       sendBuySignalMajor("ARROWS_UP");
       ARROWS_sg = "BUY";
  }
  if(ARROWS_DN != EMPTY_VALUE && ARROWS_DN != 0 && ARROWS_sg == "BUY"){
      sendSellSignalMajor("ARROWS_DN");
      ARROWS_sg = "SELL";
  }

}
 
  

  
  
      
   
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| My Custom methods                                                |
//+------------------------------------------------------------------+
//draw line object
void drawVerticalLine(int barsBack, double _color, double style, string descrip) {
      if( LastActiontimeDrawLine == Time[0]){//still the same bar
         
       }else{
          
            string lineName = "Line"+MathRand();
         
            if (ObjectFind(lineName) != 0) {
               ObjectCreate(lineName,OBJ_VLINE,0,Time[barsBack],0);
               ObjectSet(lineName,OBJPROP_COLOR, _color);//clrBlue,clrRed
               ObjectSet(lineName,OBJPROP_WIDTH,1);
               ObjectSet(lineName,OBJPROP_STYLE, style);//STYLE_SOLID//STYLE_DOT
               ObjectSetText(lineName, " " + descrip, 8, "Arial", White);
              
            }
         LastActiontimeDrawLine = Time[0];
       }
   

}

void sendSellSignalMajor(string IndicName){//---also acts as buy trade closure
sendNotification("SELL", IndicName);
IndicName = IndicName+" "+getTimeFrame();
drawVerticalLine(0, clrRed, STYLE_DOT,IndicName);

if (BuyMarketCount() > 0) {
 if(AllowCloseTradesMajor){
 CloseAllBuyOrders(Symbol(), Slippage, IndicName);
 }
}else{
    //placeOrder(orderType);
}

}
void sendBuySignalMajor(string IndicName){//---also acts as sell trade closure
sendNotification("BUY", IndicName);
IndicName = IndicName+" "+getTimeFrame();
drawVerticalLine(0, clrBlue, STYLE_DOT, IndicName);

if (BuyMarketCount() > 0) {
 if(AllowCloseTradesMajor){
  CloseAllSellOrders(Symbol(), Slippage, IndicName);
 }
}else{
    //placeOrder(orderType);
}

}
void sendSellSignalMinor(string IndicName){//---also acts as buy trade closure minors
sendNotification("MINI TREND SELL", IndicName);
IndicName = IndicName+" "+getTimeFrame();
drawVerticalLine(0, clrRed, STYLE_DOT, IndicName);

if (BuyMarketCount()) {
 if(AllowCloseTradesMinor){
  CloseAllBuyOrders(Symbol(), Slippage, IndicName);
 }
}else{
    //placeOrder(orderType);
}
}
void sendBuySignalMinor(string IndicName){//---also acts as sell trade closure minors
sendNotification("MINI TREND BUY", IndicName);
IndicName = IndicName+" "+getTimeFrame();
drawVerticalLine(0, clrRed, STYLE_DOT, IndicName);

if (BuyMarketCount() > 0) {
 if(AllowCloseTradesMinor){
 CloseAllSellOrders(Symbol(), Slippage, IndicName);
 }
}else{
    //placeOrder(orderType);
}
}

//--get current timeframe
//Time frame to string
string getTimeFrame() {
   switch (Period()) {
   case 1:
      return ("M1");
   case 5:
      return ("M5");
   case 15:
      return ("M15");
   case 30:
      return ("M30");
   case 60:
      return ("H1");
   case 240:
      return ("H4");
   case 1440:
      return ("D1");
   case 10080:
      return ("W1");
   case 43200:
      return ("MN1");
   }
   WindowRedraw();
   return (Period());
}

//-- Send Notifications
void sendNotification(string OrderType, string SignalData){

if( LastActiontimeNotification != Time[0]){//still the same bar
   string curTrades = "Cur Trds SELL["+SellMarketCount()+"] BUY["+BuyMarketCount()+"]";

   string Ls_104 = Symbol() + ", TF:" + getTimeFrame();
   string Ls_112 = Ls_104 + ", SOS EA ["+OrderType+"] SIGNAL: {"+SignalData+" "+curTrades+"}";
   string Ls_120 = Ls_112 + " @ " + TimeToStr(TimeLocal(), TIME_SECONDS)+"\n Copyright 2020, SoSCode Corp. ";
   
    SendMail(Ls_120, Ls_112);
    SendNotification(Ls_120);
    
    LastActiontimeNotification = Time[0];
      
  }

}
//-- count trades

int SellMarketCount(/*string argSymbol, int argMagicNumber*/) {
 int OrderCount;
 for (int Counter = 0; Counter <= OrdersTotal() - 1; Counter++) {
  OrderSelect(Counter, SELECT_BY_POS);
  if (/*OrderMagicNumber() == argMagicNumber && */OrderSymbol() == Symbol() &&
   OrderType() == OP_SELL) {
   OrderCount++;
  }
 }
 return (OrderCount);
}

int BuyMarketCount(/*string argSymbol, int argMagicNumber*/) {
 int OrderCount;
 for (int Counter = 0; Counter <= OrdersTotal() - 1; Counter++) {
  OrderSelect(Counter, SELECT_BY_POS);
  if (/*OrderMagicNumber() == argMagicNumber &&*/ OrderSymbol() == Symbol() &&
   OrderType() == OP_BUY) {
   OrderCount++;
  }
 }
 return (OrderCount);
}
//--close sell trades
void CloseAllSellOrders(string argSymbol, int argSlippage, string indicName) {
 for (int Counter = 0; Counter <= OrdersTotal() - 1; Counter++) {
  OrderSelect(Counter, SELECT_BY_POS);
  if ( OrderSymbol() == argSymbol && OrderType() == OP_SELL) {
   // Close Order
   int CloseTicket = OrderTicket();
   double CloseLots = OrderLots();
   while (IsTradeContextBusy()) Sleep(10);
   double ClosePrice = MarketInfo(argSymbol, MODE_ASK);
   bool Closed = OrderClose(CloseTicket, CloseLots, ClosePrice, argSlippage, Red);
   // Error Handling
   if (Closed == false) {
    int ErrorCode = GetLastError();
    string ErrDesc = ErrorDescription(ErrorCode);
    string ErrAlert = StringConcatenate("Close All Sell Orders - Error ",
     ErrorCode, ": ", ErrDesc);
    Alert(ErrAlert);
    string ErrLog = StringConcatenate("Ask: ",
     MarketInfo(argSymbol, MODE_ASK), " Ticket: ", CloseTicket, " Price: ",
     ClosePrice);
    Print(ErrLog);
    
    //+--- Please, sleep and retry again
   } else {
   Counter--;
   drawVerticalLine(0, clrRed, STYLE_DOT, "Auto Close, indic "+indicName);
   sendNotification("CLOSE SELL","" );
   
   
   }
  }
 }
}
//--close buy trades
void CloseAllBuyOrders(string argSymbol, int argSlippage, string indicName) {
 for (int Counter = 0; Counter <= OrdersTotal() - 1; Counter++) {
  OrderSelect(Counter, SELECT_BY_POS);
  if (OrderSymbol() == Symbol() &&
   OrderType() == OP_BUY) {
   // Close Order
   int CloseTicket = OrderTicket();
   double CloseLots = OrderLots();
   while (IsTradeContextBusy()) Sleep(10);
   double ClosePrice = MarketInfo(Symbol(), MODE_BID);
   bool Closed = OrderClose(CloseTicket, CloseLots, ClosePrice, argSlippage, Red);
   // Error Handling
   if (Closed == false) {
    int ErrorCode = GetLastError();
    string ErrDesc = ErrorDescription(ErrorCode);
    string ErrAlert = StringConcatenate("Close All Buy Orders - Error ",
     ErrorCode, ": ", ErrDesc);
    Alert(ErrAlert);
    string ErrLog = StringConcatenate("Bid: ",
     MarketInfo(Symbol(), MODE_BID), " Ticket: ", CloseTicket, " Price: ",
     ClosePrice);
    Print(ErrLog);
    
     //+--- Please, sleep and retry again
   } else {
   Counter--;
   drawVerticalLine(0, clrBlue, STYLE_DOT,"Auto Close, indic "+indicName);//clrBlue,clrRed//STYLE_SOLID//STYLE_DOT
   sendNotification("CLOSE BUY","Auto Close, indic "+indicName);
   
   }
  }
 }
}

