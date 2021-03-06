//+------------------------------------------------------------------+
//|                               Close Delete By Loss Or Profit.mq5 |
//|                              Copyright © 2020, Vladimir Karputov |
//|                     https://www.mql5.com/ru/market/product/43516 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2020, Vladimir Karputov"
#property link      "https://www.mql5.com/ru/market/product/43516"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>
//---
CPositionInfo  m_position;                   // object of CPositionInfo class
CTrade         m_trade;                      // object of CTrade class
CAccountInfo   m_account;                    // object of CAccountInfo class
COrderInfo     m_order;                      // object of COrderInfo class
//--- input parameters
input double      InpLoss  = -30;   // Loss, in money
input double      InpProfit= 150;   // Target profit, in money
input bool        InpManual= true;  // Only Manual ('true' -> close positions that were opened manually)
//---
bool     m_need_close_all           = false;    // close all positions
bool     m_need_delete_all          = false;    // delete all pending orders
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
//---
   if(m_need_close_all)
     {
      if(IsPositionExists())
        {
         CloseAllPositions();
         return;
        }
      else
         m_need_close_all=false;
     }
//---
   if(m_need_delete_all)
     {
      if(IsPendingOrdersExists())
        {
         DeleteAllPendingOrders();
         return;
        }
      else
         m_need_delete_all=false;
     }
//---
   double profit=ProfitAllPositions();
   if(profit<=InpLoss || profit>=InpProfit)
     {
      m_need_close_all=true;     // close all positions
      m_need_delete_all=true;    // delete all pending orders
     }
  }
//+------------------------------------------------------------------+
//| Profit all positions                                             |
//+------------------------------------------------------------------+
double ProfitAllPositions(void)
  {
   double profit=0.0;

   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if((InpManual && PositionGetInteger(POSITION_REASON)!=POSITION_REASON_EXPERT) || !InpManual)
            profit+=m_position.Commission()+m_position.Swap()+m_position.Profit();
//---
   return(profit);
  }
//+------------------------------------------------------------------+
//| Is position exists                                               |
//+------------------------------------------------------------------+
bool IsPositionExists(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if((InpManual && PositionGetInteger(POSITION_REASON)!=POSITION_REASON_EXPERT) || !InpManual)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Is pending orders exists                                         |
//+------------------------------------------------------------------+
bool IsPendingOrdersExists(void)
  {
   for(int i=OrdersTotal()-1; i>=0; i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if((InpManual && OrderGetInteger(ORDER_REASON)!=ORDER_REASON_EXPERT) || !InpManual)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if((InpManual && PositionGetInteger(POSITION_REASON)!=POSITION_REASON_EXPERT) || !InpManual)
            m_trade.PositionClose(m_position.Ticket()); // close a position
  }
//+------------------------------------------------------------------+
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
void DeleteAllPendingOrders(void)
  {
   for(int i=OrdersTotal()-1; i>=0; i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if((InpManual && OrderGetInteger(ORDER_REASON)!=ORDER_REASON_EXPERT) || !InpManual)
            m_trade.OrderDelete(m_order.Ticket());
  }
//+------------------------------------------------------------------+
