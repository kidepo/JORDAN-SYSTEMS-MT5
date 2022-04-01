
input int SL = 100; //15 pip

void OnTradeTransaction(const MqlTradeTransaction &txs, const MqlTradeRequest &req, const MqlTradeResult &res)
{
    MqlTradeRequest rq = {0};
    MqlTradeResult tr = {0};
    double sl = 0;
    if (HistoryDealGetInteger(txs.deal, DEAL_ENTRY) == DEAL_ENTRY_IN)
        if (txs.volume != 0 && txs.type != TRADE_TRANSACTION_HISTORY_UPDATE)
        {
            PositionSelect(txs.symbol);
            if (PositionGetDouble(POSITION_SL) == 0)
            {
                rq.action = TRADE_ACTION_SLTP;
                rq.symbol = PositionGetString(POSITION_SYMBOL);
                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
                {
                    sl = PositionGetDouble(POSITION_PRICE_OPEN) - SL * SymbolInfoDouble(txs.symbol, SYMBOL_POINT);
                    rq.sl = NormalizeDouble(sl, SymbolInfoInteger(txs.symbol, SYMBOL_DIGITS));
                    rq.tp = 0;
                    OrderSend(rq, tr);
                }    
                else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
                {
                    sl = PositionGetDouble(POSITION_PRICE_OPEN) + SL * SymbolInfoDouble(txs.symbol, SYMBOL_POINT);
                    rq.sl = NormalizeDouble(sl, SymbolInfoInteger(txs.symbol, SYMBOL_DIGITS));
                    rq.tp = 0;
                    OrderSend(rq, tr);
                }    
            }
        }
}
