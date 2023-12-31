// 30th June 2023
// add a begin time and trade in same direction from begin>entry>duration 
// Idea, is there any consistency on any time frame at specific time of day to buy or sell ? 

#include <Trade/Trade.mqh> // Standard Library Trade Class
CTrade trade;

input group "Risk"
input int stoploss=500; // Stoploss points or 0
input int takeprofit=0; // Takeprofit points or 0 
input double percentrisk=0.25; // Risk %
input double fixedlotsize=0; // 0 to use % 
input int maxspread=20; // Maximum spread points 
input group "Timing"
input int begin_time=420; // Begin and trade same direction 420 = 7am
input int entry_time=60; // Entry 60 minutes later
input int trade_time=60;  // Trade time for 60 minutes
input bool _mode=true; // Mode true=with trend false=reversal
input int min_change=100; // Minimum change + or - in points 

ulong _ticket=0; // ticket 
double begin_price=0; // price at begin time

int OnInit()
{ 
   return(INIT_SUCCEEDED);
}

void OnTick()
{
   double entry,lotsize,_tp,_sl;
   MqlDateTime mt;
   TimeCurrent(mt);
   int t=mt.hour*60+mt.min; // 485 = 805am 
   
   if(_ticket==0) // no ticket so wait for entry
   {
      if(t==begin_time && begin_price==0)
      {
         begin_price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
      }
   
      if(t==begin_time+entry_time && begin_price!=0) // time to enter trade ? use begin_price only once 
      {      
         double spread=SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SymbolInfoDouble(Symbol(),SYMBOL_BID);
         if(spread>(maxspread*Point()) ) { Print("Spread ",DoubleToString(spread,Digits()) ); begin_price=0; return; } // > maximum spread , reset
         
         double diff_price=SymbolInfoDouble(Symbol(),SYMBOL_ASK)-begin_price;
         double change_price_min=min_change*Point(); // 0.00100 10pips
         begin_price=0; // reset 
         
         Print("Difference in price ",DoubleToString(diff_price,Digits())," Minimum change ",DoubleToString(change_price_min,Digits()),MathAbs(diff_price)<change_price_min ? " Too Low" : " Ok" );
         
         if((_mode && diff_price>change_price_min) || (!_mode && diff_price<-change_price_min) ) // buy either with trend and higher price or reversal and lower price
         {
            entry=SymbolInfoDouble(Symbol(),SYMBOL_ASK); 
            if(takeprofit)_tp=entry+(takeprofit*Point()); else _tp=0;
            if(stoploss)_sl=entry-(stoploss*Point()); else _sl=0;
            lotsize=CalcLotsize(stoploss*Point()); // 500 points = 50 pips = 0.00500 for EURUSD 5 digits or 0.500 for USDJPY 3 digits 
            if(lotsize!=0)
            {
               if(trade.Buy(lotsize,NULL,entry,_sl,_tp,NULL))
               {
                  if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
                  Print("Buy ",trade.ResultRetcode()," ",_ticket," Time ",t);
               }
               else Print("Buy Error ",GetLastError());
            }
         }
         else if((_mode && diff_price<-change_price_min) || (!_mode && diff_price>change_price_min) ) // sell either with trend and lower price or reversal and higher price
         {
            entry=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            if(takeprofit)_tp=entry-(takeprofit*Point()); else _tp=0;
            if(stoploss)_sl=entry+(stoploss*Point()); else _sl=0;
            lotsize=CalcLotsize(stoploss*Point()); // 500 points = 50 pips = 0.00500 for EURUSD 5 digits or 0.500 for USDJPY 3 digits 
            if(lotsize!=0)
            {
               if(trade.Sell(lotsize,NULL,entry,_sl,_tp,NULL))
               {
                  if(trade.ResultRetcode()==TRADE_RETCODE_DONE) _ticket=trade.ResultOrder();
                  Print("Sell ",trade.ResultRetcode()," ",_ticket," Time ",t);
               }
               else Print("Sell Error ",GetLastError());
            }
         }
      }               
   }
   else // do have a ticket 
   {
      if(t==begin_time+entry_time+trade_time) // exit
      {
         if(PositionSelectByTicket(_ticket))
         {
            trade.PositionClose(_ticket,ULONG_MAX); // close
            Print("Close ",trade.ResultRetcode()," ",_ticket," Time ",t);
            _ticket=0;
         }
         else Print("Close ",_ticket," Error ",GetLastError());
      }  
       
      if(!PositionSelectByTicket(_ticket))_ticket=0; // if we can't select the ticket it's probably closed so reset _ticket to 0 
   }   
}

double CalcLotsize(double pricerisk) // i.e. 0.00100 is risk 100 points, 10 pips
{
   if(fixedlotsize) return fixedlotsize;

   double ticksrisked=pricerisk/SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE); // 0.00100 / 0.00001 = 100 ticks ( tick is usually same as point ) 
   double tickvalue=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE); // cash risked in account currency per 1.00 per tick , EURUSD ~ £0.75 per 1.00 per 0.00001 tick 
   double cashrisk=AccountInfoDouble(ACCOUNT_BALANCE)*percentrisk*0.01; // £10000 * 1 * 1%(0.01) = £100
   double ideallotsize=cashrisk/(ticksrisked*tickvalue); // £100 / ( 100 * 0.75 ) = 1.33 > $130 > $1.30 per point > $13/pip for 10 pips risked
   
   double tmplotsize=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN); // start at i.e. 0.01 
   double tmp=0;
   
   while(true) // find nearest correct lotsize < 1%
   {
      if(tmplotsize>ideallotsize) break;
      if(tmplotsize>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) break; // maximum trade size   
      tmp=tmplotsize; // update
      tmplotsize+=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP); // next step
   }
   
   Print("Ideal lotsize=",DoubleToString(ideallotsize,4)," Rounded down to ",DoubleToString(tmp,2)); // show ideal size 
   return(tmp);
}
