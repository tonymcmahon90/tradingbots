#include <Trade/Trade.mqh>
CTrade trade;

input int _tp=0; // Takeprofit points
input int _sl=0; // Stoploss points
input double lotsize=0.1; // Lotsize
input int period=10; // Period
input ENUM_MA_METHOD method=MODE_SMA; // Method
input ENUM_APPLIED_PRICE _price=PRICE_CLOSE; // Price
input bool oncepercandle=false; // Once per candle 
input int enter_abovebelow=100; // Entry distance above or below points to trigger
input int exit_abovebelow=100; // Exit distance above or below points to trigger

int hMA;
double bMA[];
ulong _ticket,_type;

int OnInit()
{
   hMA=iMA(NULL,0,period,0,method,_price);
   ArraySetAsSeries(bMA,true);
   return(INIT_SUCCEEDED);
}

void OnTick()
{   
   static datetime t=iTime(NULL,0,0);  
   if(oncepercandle && iTime(NULL,0,0)==t) return; else t=iTime(NULL,0,0); // only test when got new candle
   
   CopyBuffer(hMA,0,0,3,bMA);
   double entry=0,takeprofit=0,stoploss=0;
   
   if(_ticket==0) // no trade
   {
      if(SymbolInfoDouble(_Symbol,SYMBOL_BID)>bMA[0]+(enter_abovebelow*_Point)) // MA uses bid price
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         if(_tp)takeprofit=entry+(_tp*_Point);
         if(_sl)stoploss=entry-(_sl*_Point);
         
         if(trade.Buy(lotsize,NULL,entry,stoploss,takeprofit,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }
      else if(SymbolInfoDouble(_Symbol,SYMBOL_BID)<bMA[0]-(enter_abovebelow*_Point)) // sell
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         if(_tp)takeprofit=entry-(_tp*_Point);
         if(_sl)stoploss=entry+(_sl*_Point);
      
         if(trade.Sell(lotsize,NULL,entry,stoploss,takeprofit,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
         }
      }
   }
   else // got ticket
   {
      if(!PositionSelectByTicket(_ticket)){ _ticket=0; return; } // closed tp or sl 
   
      if(PositionSelectByTicket(_ticket)) _type=PositionGetInteger(POSITION_TYPE); else return; 
   
      if(_type==POSITION_TYPE_BUY)
      {
         if(SymbolInfoDouble(_Symbol,SYMBOL_BID)>bMA[0]-(exit_abovebelow*_Point)) return; // stay in buy
         
         if(trade.PositionClose(_ticket)){ _ticket=0; return; } // close
      }
      
      if(_type==POSITION_TYPE_SELL)
      {
         if(SymbolInfoDouble(_Symbol,SYMBOL_BID)<bMA[0]+(exit_abovebelow*_Point)) return; // stay in sell
         
         if(trade.PositionClose(_ticket)){ _ticket=0; return; } // close
      }
   }
}