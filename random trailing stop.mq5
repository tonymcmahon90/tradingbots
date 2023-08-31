#include <Trade\Trade.mqh>
CTrade trade;

enum _riskmode{Fixed,Percent,Cash};
input group "SL/TP"
input int _sl=300; // Stoploss points
input int _tp=300; // Takeprofit points or 0
input bool _usetrailingstop=true; // Use trailing stop
input int trailing_stop=300; // Trailing stop points
input int trailing_step=30; // Trailing step points
input int trailing_min=150; // Start trailing at points
input group "Risk management"
input _riskmode riskmode=Percent; // Risk mode
input double _lotsize=0.01; // Fixed lotsize
input double riskpercent=1.0; // Risk percent
input double riskcash=100; // Risk cash

bool showdebug=true;
ulong _order=0;

int OnInit()
{
   MathSrand(GetTickCount()); // seed random
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   double entry,lots,tmp_tp;
   
   if(_order!=0) // if got order
   {   
      if(!PositionSelectByTicket(_order)) _order=0; // reset 
      else if(_usetrailingstop) TrailingStop(); // trailing stop            
      return;
   }
   
   if(MathRand()<16384)
   {
      entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      lots=CalcLots(_sl*_Point);
      if(_tp)tmp_tp=entry+(_tp*_Point);
      else tmp_tp=0;
      
      if(lots)
      if(trade.Buy(lots,_Symbol,entry,entry-(_sl*_Point),tmp_tp,"Random Buy"))
      {
         if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _order=trade.ResultOrder(); else Print("Buy error");
      }
   }
   else
   {
      entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      lots=CalcLots(_sl*_Point);
      if(_tp)tmp_tp=entry-(_tp*_Point);
      else tmp_tp=0;
      
      if(lots)
      if(trade.Sell(lots,_Symbol,entry,entry+(_sl*_Point),tmp_tp,"Random Sell"))
      {
         if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _order=trade.ResultOrder(); else Print("Sell error");
      }
   }
}

double CalcLots(double risk_price)
{
   if(riskmode==Fixed) return _lotsize;  // Fixed   
   double risk;  
   if(riskmode==Percent)  // Percent
      risk=AccountInfoDouble(ACCOUNT_EQUITY)*(riskpercent*0.01); // optionally use balance 
   else   // Cash
      risk=riskcash;
   
   double ticks=risk_price/SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE); // number of ticks i.e. 0.01000 / 0.00001 = 1000 ticks
   double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE); // tick value for 1.00 contract/lots in account currency 
   double onelot=ticks*tick_value; // 1.00 risk
   double ideallots=risk/onelot; // ideal lotsize    
   double tmp_lots=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN); // minimum 
   
   if(ideallots<tmp_lots)
   {
      if(showdebug) Print("Ideal lots ",ideallots,"(",tmp_lots,") Risk ",tmp_lots*onelot);
      return 0; // not enough to place minimum trade 
   }
   
   while(true) // calculate nearest yet under lotsize
   {
      if(tmp_lots+SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP)>ideallots) break;
      if(tmp_lots+SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP)>SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX)) break;
      tmp_lots+=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   }
   if(showdebug) Print("Ideal lots ",ideallots,"(",tmp_lots,") Risk ",tmp_lots*onelot);   
   return NormalizeDouble(tmp_lots,2);
}

void TrailingStop()
{
   // get current price depending on a buy or sell
   double current_price,stop_loss=PositionGetDouble(POSITION_SL),open=PositionGetDouble(POSITION_PRICE_OPEN),take_profit=PositionGetDouble(POSITION_TP);
   
   if(PositionGetInteger(POSITION_TYPE)==(ENUM_POSITION_TYPE)POSITION_TYPE_BUY)
   { 
      current_price=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      if(current_price>=open+(trailing_min*_Point)) // at least at minumum to move stoploss 
      {
         if((stop_loss+(trailing_step*_Point))<(current_price-(_sl*_Point)))
         {
            // assume hedging _order
            if(!trade.PositionModify(_order,current_price-(_sl*_Point),take_profit)) Print("Problem modify stoploss Buy");
         }      
      }
   }
   else
   {
      current_price=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      if(current_price<=open-(trailing_min*_Point)) // at least at minumum to move stoploss 
      {
         if((stop_loss-(trailing_step*_Point))>(current_price+(_sl*_Point)))
         {
            // assume hedging _order
            if(!trade.PositionModify(_order,current_price+(_sl*_Point),take_profit)) Print("Problem modify stoploss Sell");
         }      
      }      
   }   
}