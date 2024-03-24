//+------------------------------------------------------------------+
//|                                                     JC-PILOT.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Jordan Capital Inc."
#property link      "https://www.buymeacoffee.com/jordancapitalfx"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Wininet.mqh>
//#include <stdlib.h>
//#include <stderror.mqh>
#include <Trade\Trade.mqh>

#define ENDPOINT_URL "http://127.0.0.1:8081/api/check-orders"
#define INTERVAL_SECONDS 30 // Interval in seconds (e.g., every 1 minute)

string signalOrderType = "";
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
   static datetime lastCallTime = 0;

   if(TimeCurrent() - lastCallTime >= INTERVAL_SECONDS)
     {
      checkAvailableSignal();
      lastCallTime = TimeCurrent();
     }
  }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---

  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void checkAvailableSignal()
  {
//--- Your tick code here
// Example of sending a POST request in the OnTick function

   string url = "http://127.0.0.1:808/api/check-orders";
   string postData = "{\"asset\": \"GBPUSD\", \"tf\": \"1\", \"signalOrderType\": \"ANY\", \"broker\": \"DEFAULT\", \"strategyName\": \"UHLMA\", \"license\": \"hellojc\"}";
   char DataArr[];      // the array of the HTTP message body
   StringToCharArray(postData, DataArr);

   char result[];       //an array containing server response data
   char error[];
   int timeout = 5000; // Timeout in milliseconds
   string result_headers  = "";
   string cookie=NULL;
   string headers = "Content-Type: application/json";

   Print("Out going request to upstream: ", postData  ," @ ", url);
   int res = WebRequest("POST", url,headers, timeout, DataArr, result, result_headers);

   if(res==-1)
     {
      signalOrderType = "";
      Print("Error in WebRequest. Error code  =",GetLastError());
      //--- Perhaps the URL is not listed, display a message about the necessity to add the address
      MessageBox("Add the address '"+url+"' to the list of allowed URLs on tab 'Expert Advisors'","Error",MB_ICONINFORMATION);
     }
   else
      if(res == 200)//--- Successful
        {

         string response = CharArrayToString(result);
         Print("Response: ", response);
         // Process the JSON response here //StringFind(response, "BUY") >= 0

         string signalOrderType = "";
         if(StringFind(response, "\"signalOrderType\":\"BUY\"") > -1)
           {
            signalOrderType = "BUY";
            Print("[BUY] signal has been set:\n");
           }
         else
            if(StringFind(response, "\"signalOrderType\":\"SELL\"") > -1)
              {
               signalOrderType = "SELL";
               Print("[SELL] signal has been set:\n");
              }
            else
              {
               Print("Unknown response received:", response);
               // Handle unknown response scenario (optional)
               signalOrderType = "";
              }

        }
      else
         if(res == 404)//--- not found
           {
            signalOrderType = "";
            Print("No record/signal found yet.");

           }
         else
           {
            signalOrderType = "";
            Print("Unknown response code returned ["+ res +"]");
            Print("Error in WebRequest. @endpoint: ", url, ", Error: ", GetLastError());

           }

  }

//+------------------------------------------------------------------+
bool OrderCommentExists(const string comment)
{
    int totalOrders = OrdersTotal(); // Total orders including history
    for (int i = 0; i < totalOrders; i++)
    {
        if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) // Select order by position
        {
            if (OrderComment() == comment || StringFind(OrderComment(), comment) >= 0)
            {
                return true; // Found matching comment
            }
        }
    }
    return false; // Comment not found in any order
}