// fast version [1],[2] is optionally [0],[1] _now
// multiple trades, buy and sell signals place trades then scan for magic number to close on signals 
// main slope or crossover RVI

#include <Trade/Trade.mqh> // Standard Library Trade Class
CTrade trade;

input group "Trade"
input double lotsize=0.1; // Lotsize
input int _stoploss=500; // Stoploss in points or 0
input int _takeprofit=0; // Takeprofit in points or 0 
input bool fast_mode=true; // Fast mode
input ulong buy_magic=9201; // Buy Magic
input ulong sell_magic=9202; // Sell Magic 
input bool multi_trades=false; // Multiple trades
input group "EMA"
input bool ema_filter=true; // Use EMA filter
input int ema_period=10; // EMA period
input ENUM_APPLIED_PRICE ema_price=PRICE_TYPICAL; // EMA price
input group "RVI"
input int rvi_period=10; // RVI period
enum rvi_m{Crossover,Slope};
input rvi_m _mode=Slope; // RVI signal mode
input group "Level filter"
input bool level_filter=true; // Use level filter
input double buy_level=-0.1; // Buy level
input double sell_level=0.1; // Sell level

int hMA,hRVI,_now;
double bMA[],bRVImain[],bRVIsignal[];

int OnInit()
{
   hMA=iMA(Symbol(),PERIOD_CURRENT,ema_period,0,MODE_EMA,ema_price);
   ArraySetAsSeries(bMA,true); // right[0] to left
   hRVI=iRVI(Symbol(),PERIOD_CURRENT,rvi_period);
   ArraySetAsSeries(bRVImain,true); 
   ArraySetAsSeries(bRVIsignal,true);     
   if(fast_mode) _now=0; else _now=1; // fast is [0],[1] slower is [1],[2] signal 
   return(INIT_SUCCEEDED);
}

bool RVIBuy()
{
   if(bRVImain[_now]>buy_level && level_filter) return false;
   
   if(_mode==Crossover){ if(bRVImain[_now]>bRVIsignal[_now] && bRVImain[_now+1]<bRVIsignal[_now+1]) return true; }
   else if(_mode==Slope){ if(bRVImain[_now]>bRVImain[_now+1]) return true; }
   return false;
}

bool RVISell()
{
   if(bRVImain[_now]<sell_level && level_filter) return false;
   
   if(_mode==Crossover){ if(bRVImain[_now]<bRVIsignal[_now] && bRVImain[_now+1]>bRVIsignal[_now+1]) return true; }
   else if(_mode==Slope){ if(bRVImain[_now]<bRVImain[_now+1]) return true; }    
   return false;
}

void OnTick()
{  
   double entry,_stop,_tp;
   
   CopyBuffer(hMA,0,0,3,bMA); // [0],[1],[2] 
   CopyBuffer(hRVI,0,0,3,bRVImain);
   CopyBuffer(hRVI,1,0,3,bRVIsignal);
   
   static bool placed_trade=false; // one trade per candle if multiple trades 
   static datetime _t=iTime(NULL,0,0);
   if(iTime(NULL,0,0)!=_t){ if(multi_trades)placed_trade=false; _t=iTime(NULL,0,0); } // reset
   
   if(RVIBuy() && placed_trade==false) // one trade per candle 
   {
      if(bMA[_now]>bMA[_now+1] || ema_filter==false) // want slope up trend ( was [1],[2] now [_now],[_now+1] could do ema_fast_mode=true
      { 
         entry=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         if(_stoploss!=0)_stop=entry-(_stoploss*_Point); else _stop=0;
         if(_takeprofit!=0)_tp=entry+(_takeprofit*_Point); else _tp=0;
         trade.SetExpertMagicNumber(buy_magic);
         
         if(trade.Buy(lotsize,Symbol(),entry,_stop,_tp,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) placed_trade=true;                                    
         }
      }         
   }
          
   if(RVISell() && placed_trade==false)   
   {
      if(bMA[_now]<bMA[_now+1] || ema_filter==false)
      {
         entry=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         if(_stoploss!=0)_stop=entry+(_stoploss*_Point); else _stop=0;
         if(_takeprofit!=0)_tp=entry-(_takeprofit*_Point); else _tp=0;
         trade.SetExpertMagicNumber(sell_magic);
         
         if(trade.Sell(lotsize,Symbol(),entry,_stop,_tp,NULL))
         {
            if(trade.ResultRetcode()==TRADE_RETCODE_DONE) placed_trade=true;                        
         }
      }
   }  
      
   ulong _ticket=0;
   int n_positions=0;
   for(int n=0;n<=PositionsTotal();n++)
   {
      _ticket=PositionGetTicket(n);
      if(PositionSelectByTicket(_ticket))
      {
         if(PositionGetInteger(POSITION_MAGIC)==(long)buy_magic)
         {
            n_positions++;
            if(RVISell()) { if(trade.PositionClose(_ticket,ULONG_MAX)){ Print("Autoclosed Buy"); if(!multi_trades) placed_trade=false; return; } } // exit trade   
         }
         if(PositionGetInteger(POSITION_MAGIC)==(long)sell_magic)
         {
            n_positions++;
            if(RVIBuy()) { if(trade.PositionClose(_ticket,ULONG_MAX)){ Print("Autoclosed Sell"); if(!multi_trades) placed_trade=false; return; } } // exit trade   
         }
      }  
   }
   
   if(!multi_trades && n_positions==0) placed_trade=false; // reset
}