//+------------------------------------------------------------------+
//|                                                       Tester.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include <Expert\Signal\SignalMACD.mqh>
//--- available trailing
#include <Expert\Trailing\TrailingMA.mqh>
//--- available money management
#include <Expert\Money\MoneySizeOptimized.mqh>
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
// Define input parameters
input double lotSize = 0.1;        // Lot size for trades
input double stopLossMoney = 50.0;  // Stop loss in account currency
input double takeProfitMoney = 100.0; // Take profit in account currency
input int slippage = 3;            // Maximum allowed slippage
input int magicNumber = 12345;     // Magic number to identify trades
input int maxOpenTrades = 5;       // Maximum number of open trades

// Define global variables
int ticket;                        // Trade ticket number
int buySignal = 1;                 // Custom indicator buy signal
int sellSignal = -1;               // Custom indicator sell signal

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Add your initialization code here, if needed
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Add your deinitialization code here, if needed
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check if we have reached the maximum number of open trades
   if (OrdersTotal() >= maxOpenTrades)
       return;

   // Calculate stop loss and take profit levels based on current prices
 //  double stopLossPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) - stopLossMoney / MarketInfo(Symbol(), MODE_MARGINREQUIRED), MarketInfo(Symbol(), MODE_DIGITS));
 //  double takeProfitPrice = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) + takeProfitMoney / MarketInfo(Symbol(), MODE_MARGINREQUIRED), MarketInfo(Symbol(), MODE_DIGITS));

   double SonicTrendSigBuy[];
	double SonicTrendSigSell[];
		
	ArraySetAsSeries(SonicTrendSigBuy,true);
	ArraySetAsSeries(SonicTrendSigSell,true);
	
   // Check for a buy signal from the custom indicator
   int SonicTendHandle  = iCustom(Symbol(), 0, "silver-trend-signal-alert");
   
   
   //double sellSignal = iCustom(Symbol(), 0, "silver-trend-signal-alert");
   
   CopyBuffer(SonicTendHandle,1,0,3,SonicTrendSigBuy);//Sonic Trend Signal Buy
	CopyBuffer(SonicTendHandle,0,0,3,SonicTrendSigSell);//Sonic Trend Signal Sell
	
	
		
   if ( SonicTrendSigBuy[1] > 0 && SonicTrendSigBuy[1] != EMPTY_VALUE)
   {
   Print("buying");
   Print(SonicTrendSigBuy[1]);
      // Open a buy trade
      //ticket = OrderSend(Symbol(), OP_BUY, lotSize, MarketInfo(Symbol(), MODE_ASK), slippage, 0, stopLossPrice, "", magicNumber, clrNONE, takeProfitPrice);
   }
   // Check for a sell signal from the custom indicator
    if (SonicTrendSigSell[1] > 0 && SonicTrendSigSell[1] != EMPTY_VALUE)
   {
   Print("selling");
   Print(SonicTrendSigSell[1]);
      // Open a sell trade
      //ticket = OrderSend(Symbol(), OP_SELL, lotSize, MarketInfo(Symbol(), MODE_BID), slippage, 0, stopLossPrice, "", magicNumber, clrNONE, takeProfitPrice);
   }
}

//+------------------------------------------------------------------+
