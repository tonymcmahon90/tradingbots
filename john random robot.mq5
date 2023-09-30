#include <Trade/Trade.mqh>
CTrade trade;

ulong _ticket; 

input double lotsize=0.01; // Lotsize 
input int _stoploss=300; // Stoploss in points 
input int _takeprofit=300; // Takeprofit in points

int OnInit()
{
   MathSrand(GetTickCount());
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   double entry;
   
   if(_ticket==0)
   {
      if(MathRand()<16384)
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         if(trade.Buy(lotsize,_Symbol,entry,entry-(_stoploss*_Point),entry+(_takeprofit*_Point),"Buy"))
         { if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder(); }         
      }
      else
      {
         entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         if(trade.Sell(lotsize,_Symbol,entry,entry+(_stoploss*_Point),entry-(_takeprofit*_Point),"Sell"))
         { if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder(); }  
      }
   }
   else
   {
      if(!PositionSelectByTicket(_ticket)) _ticket=0; // reset    
   }
}