//+------------------------------------------------------------------+
//|                                                       RANGER.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jordan Capital Inc."
#property link      "https://www.jordancapital.com"
#property version   "2023.06.06@10:22"
//+------------------------------------------------------------------+
//| ToDO's                                                           |
//+------------------------------------------------------------------+
//study prices long and ranges


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


//+------------------------------------------------------------------+
//| Input variables                                                  |
//+------------------------------------------------------------------+
input bool PlaceTradesInPut = true;
input int PipThreshold = 600;  // Minimum number of pips for trade entry
input int TakeProfitPips_ = 200;  // Take profit in pips
input double volume_=0.01;
input double maxVolume=0.12;
input ulong MyMagicNumber = 0;
input bool setStopLoss = false;
input bool setTakeProfit = false;
int prevCandleIndex = 1;
int TotalAccMaximumTradeCount = 1;
input bool useHyperRecoverFactor = true;
input double HyperRecoverFactorBy = 0.5;
input double customRecoverFactorBy = 2.0;
input bool turnOnRangeOrders = false;
input int RangeOrdersCount_ = 3;


//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
string EA_Version = "#jc.ranger.v1";
enum orderType
  {
   orderBuy,
   orderSell
  };

datetime candleTimes[],lastCandleTime;

MqlTradeRequest request;
MqlTradeResult result;
MqlTradeCheckResult checkResult;
long Slippage = 3;
int MagicNumber=0;

double stopLoss = 0.0;
double takeProfit = 0.0;
bool PlaceTrades = PlaceTradesInPut;
int TakeProfitPips = TakeProfitPips_;
double volume= volume_;
int RangeOrdersCount = RangeOrdersCount_;
string lastSignal = "NONE";
double lastBuyEntryPrice = 0.0;
double lastSellEntryPrice = 0.0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   // Check if the symbol is EURUSD
   if (_Symbol == "Range Break 200 Index" /*|| _Symbol == "Range Break 100 Index"*/)
   {
       
   }else{
       Print("Symbol is not a Range Break Index. EA initialization failed.");
       Alert("Symbol is not a Range Break Index. EA initialization failed.");
       return (INIT_FAILED);
   }
   
   // Check if the timeframe is one minute
   if (Period() != PERIOD_M1)
   {
      Print("Timeframe is not 1 minute. EA initialization failed.");
      Alert("Timeframe is not 1 minute. EA initialization failed.");
      return (INIT_FAILED);
   }
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


// Function to calculate pip value
double CalculatePipValue()
  {
   double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickSize == 0.00001 || tickSize == 0.001)  // Assuming 5 decimal places or 3 decimal places
      pipValue *= 10;

   return pipValue;
  }

// Function to check if the previous candle is bullish
bool IsBullishCandle(int index)
  {
   return (iOpen(_Symbol, 0, index) < iClose(_Symbol, 0, index));
  }

// Function to check if the previous candle is bearish
bool IsBearishCandle(int index)
  {
   return (iOpen(_Symbol, 0, index) > iClose(_Symbol, 0, index));
  }

// Entry function
void OnTick()
  {
// rechecking if magic number is set
   if(MagicNumber <= 0 && MyMagicNumber <= 0)
     {
      MagicNumber = MathAbs(ChartID());
      if(MagicNumber <= 0)
        {
         MagicNumber = MagicNumber * -1;
        }
      printf("MagicNumber AutoSet To => "+ MagicNumber);
     }
   else
      if(MyMagicNumber > 0)
        {
         MagicNumber = MyMagicNumber;
        }
//Trade.MagicNumber(MagicNumber);

   double pipValue = CalculatePipValue();
   double pipThresholdValue = PipThreshold * pipValue;
   double takeProfitValue = TakeProfitPips * pipValue;


// Display mini dashboard
   Comment("Previous Candle:",
           "<>Open: ", DoubleToString(iOpen(_Symbol, 0, prevCandleIndex), _Digits),
           "<>Close: ", DoubleToString(iClose(_Symbol, 0, prevCandleIndex), _Digits),
           "<>Difference: ", MathAbs(DoubleToString(iClose(_Symbol, 0, prevCandleIndex) - iOpen(_Symbol, 0, prevCandleIndex), _Digits)),
           "<>Tradable: ", (IsBullishCandle(prevCandleIndex) && (iClose(_Symbol, 0, prevCandleIndex) - iOpen(_Symbol, 0, prevCandleIndex)) > PipThreshold)
           || (IsBearishCandle(prevCandleIndex) && (iOpen(_Symbol, 0, prevCandleIndex) - iClose(_Symbol, 0, prevCandleIndex)) > pipThresholdValue) ? "Yes" : "No",
           "<>Pip Threshold: ", DoubleToString(PipThreshold, 0),
           "<>Take Profit Pips: ", DoubleToString(TakeProfitPips, 0),
           "<>Pip Value: ", DoubleToString(pipValue, 3),
           "<>pipThresholdValue: ", DoubleToString(pipThresholdValue, 3)
          );
//Print( pipValue);

   if(IsBullishCandle(prevCandleIndex) && (iClose(_Symbol, 0, prevCandleIndex) - iOpen(_Symbol, 0, prevCandleIndex)) > pipThresholdValue && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades)
     {
      // Open sell trade
      if(lastSignal == "BUY"){
       RangeOrdersCount = RangeOrdersCount_;
      }
      lastSignal = "SELL";
      double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      lastSellEntryPrice = entryPrice;
      stopLoss = entryPrice + takeProfitValue;
      takeProfit = entryPrice - takeProfitValue;


      if(!makePosition(orderSell))
        {
         Print("Failed to open sell trade. Error code: ", GetLastError());
        }
     }
   else
      if(IsBearishCandle(prevCandleIndex) && (iOpen(_Symbol, 0, prevCandleIndex) - iClose(_Symbol, 0, prevCandleIndex)) > pipThresholdValue && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades)
        {
         // Open buy trade
         if(lastSignal == "SELL"){
            RangeOrdersCount = RangeOrdersCount_;
         }
         lastSignal = "BUY";
         double entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         lastBuyEntryPrice = entryPrice;
         stopLoss = entryPrice - takeProfitValue;
         takeProfit = entryPrice + takeProfitValue;

         if(!makePosition(orderBuy))
           {
            Print("Failed to open buy trade. Error code: ", GetLastError());
           }
        }
        
        //range trading
        //selling
        if(turnOnRangeOrders && lastSignal == "SELL" && RangeOrdersCount > 0 && MathAbs(lastSellEntryPrice - SymbolInfoDouble(_Symbol, SYMBOL_BID)) <3 && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades){
            if(!makePosition(orderSell))
           {
            Print("Failed to open sell trade. Error code: ", GetLastError());
           }else{
            Print("Range sell Trade placed successfully");
            RangeOrdersCount = RangeOrdersCount - 1;
           }
        }
        //buying
        if(turnOnRangeOrders && lastSignal == "BUY" && RangeOrdersCount > 0 && MathAbs(lastBuyEntryPrice - SymbolInfoDouble(_Symbol, SYMBOL_ASK)) <3 && TotalAccMaximumTradeCount > PositionsTotal() && PlaceTrades){
            if(!makePosition(orderBuy))
           {
            Print("Failed to open buy trade. Error code: ", GetLastError());
           }else{
           Print("Range buy Trade placed successfully");
            RangeOrdersCount = RangeOrdersCount - 1;
           }
        }

// Specify the maximum allowed price difference

   CloseTradesWithPriceDifference(takeProfitValue);



  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseTradesWithPriceDifference(double priceDifference)
  {
   int totalPositions = PositionsTotal();
   for(int i = totalPositions - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_LAST);
         //SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double difference = MathAbs(currentPrice - entryPrice);

         if(difference > priceDifference)
           {
            double profit = PositionGetDouble(POSITION_PROFIT);
            bool isLoss = profit < 0.0; // Check if the trade closed at a loss

            // Perform actions based on the trade result
            if(isLoss)
              {
               // Increase lot size for next trade
               double originalLotSize = PositionGetDouble(POSITION_VOLUME);

               if(useHyperRecoverFactor)
                 {
                  double multiFactor = (difference/priceDifference) * HyperRecoverFactorBy;
                  if(multiFactor < 2){
                  Print("New multiFactor was #1 => :"+DoubleToString(multiFactor, 4)+" Been set to "+DoubleToString(customRecoverFactorBy, 4));
                     multiFactor = customRecoverFactorBy;
                  }
                  volume = originalLotSize * multiFactor;
                   if(volume > maxVolume){
                     volume = maxVolume;
                   }
                  
                  Print("New originalLotSize #1 => :"+DoubleToString(originalLotSize, 4));
                  Print("New currentPrice #1 => :"+DoubleToString(currentPrice, 4));
                  Print("New entryPrice #1 => :"+DoubleToString(entryPrice, 4));
                  Print("New difference #1 => :"+DoubleToString(difference, 4));
                  Print("New priceDifference #1 => :"+DoubleToString(priceDifference, 4));
                  Print("New HyperRecoverFactorBy #1 => :"+DoubleToString(HyperRecoverFactorBy, 4));
                  Print("New multiFactor #1 => :"+DoubleToString(multiFactor, 4));
                  Print("New Calculated volume #1 => :"+DoubleToString(volume, 4));
                  Print(volume);
                 }
               else
                 {
                  volume = originalLotSize * customRecoverFactorBy; // Adjust the factor as per your strategy
                  Print("New Calculated volume #2 => :"+DoubleToString(volume, 4));
                   Print(volume);
                 }

               TakeProfitPips = TakeProfitPips_ * 1.5;

              }
            else
              {
               // Use original lot size for the next trade
               double originalLotSize = PositionGetDouble(POSITION_VOLUME);
               volume = volume_;
               TakeProfitPips = TakeProfitPips_;
               // Place your code to open a new trade with originalLotSize
              }

            //PositionClose(ticket);
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
              {
               //BuyCount++;
               TradeX.PositionCloseCustom(_Symbol,MagicNumber,Slippage,"BUY");
              }
            else
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                 {
                  //SellCount++;
                  TradeX.PositionCloseCustom(_Symbol,MagicNumber,Slippage,"SELL");
                 }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool makePosition(orderType type)
  {
   ZeroMemory(request);
   request.symbol=_Symbol;
   request.volume=volume;
   request.action=TRADE_ACTION_DEAL;
   request.type_filling=ORDER_FILLING_FOK;
   request.magic = MagicNumber;
   request.comment = EA_Version+" TF:"+GetTimeFrame();
   double price=0;

   if(type==orderBuy)
     {
      //Buy
      request.type=ORDER_TYPE_BUY;
      price=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
      if(setStopLoss)
         request.sl=NormalizeDouble(price-stopLoss,_Digits);
      if(setTakeProfit)
         request.tp=NormalizeDouble(price+takeProfit,_Digits);

     }
   else
      if(type==orderSell)
        {
         //Sell
         request.type=ORDER_TYPE_SELL;
         price=NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
         if(setStopLoss)
            request.sl=NormalizeDouble(price+stopLoss,_Digits);
         if(setTakeProfit)
            request.tp=NormalizeDouble(price-takeProfit,_Digits);

        }
   request.deviation=10;
   request.price=price;


   if(OrderCheck(request,checkResult))
     {
      Print("Checked!");
     }
   else
     {
      Print("Not Checked! ERROR :"+IntegerToString(checkResult.retcode));
      
      int error_temp = GetLastError(); 
      Print("@ --- (Function = "+(__FUNCTION__)+") --- ERROR("+(string)error_temp+ ") = "+ErrorDescription(error_temp));
      //Print("Retcode("+(string)result.retcode+ ") = "+RetcodeDescription(result.retcode));
                                
      return false;
     }

   if(OrderSend(request,result))
     {
      Print("Ordem enviada com sucesso!");
     }
   else
     {
      Print("Ordem não enviada!");
      return false;
     }

   if(result.retcode==TRADE_RETCODE_DONE || result.retcode==TRADE_RETCODE_PLACED)
     {
      Print("Trade Placed!");
      return true;
     }
   else
     {
      return false;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string GetTimeFrame()
  {
   int period = Period();
//switch(Period())
// {
   if(period == 1)
      return ("M1");
   else
      if(period == 5)
         return ("M5");
      else
         if(period == 15)
            return ("M15");
         else
            if(period == 30)
               return ("M30");
            else
               if(period == 60)
                  return ("H1");
               else
                  if(period == 240)
                     return ("H4");
                  else
                     if(period == 1440)
                        return ("D1");
                     else
                        if(period == 10080)
                           return ("W1");
                        else
                           if(period == 43200)
                              return ("MN1");
//}

   return (Period());
  }
//+------------------------------------------------------------------+
