// 26th June 2023 
// simplest random forex robot with reasonable error checking and risk % calc and trailing stoploss 
// this robot opens a trade on a chart regardless of any other trades
// it gets the ticket number of the random buy or sell trade and resets when the order closes and then opens another random trade
// this version adds trailing stoploss
// this robot works on CFD or SpreadBetting 

#property strict // new MQL4

input int stoploss=100; // Trailing Stoploss in points
input int takeprofit=100; // Takeprofit in points or 0
// some brokers have minimum 0.02 others might be spread betting hence 0.10 = 10p/pip 
input double lotsize=0; // Lotsize
input double riskpercent=0.1; // Risk % if Lotsize=0
input bool closeonexit=true; // Close on exit EA 

int ticket; // got from OrderSend() otherwise 0 
datetime update; // used to trail stop once per candle

int OnInit()
{
   MathSrand(GetTickCount()); // ms since system start
   ticket=0;
   update=iTime(NULL,0,0);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(ticket && closeonexit) // got an open trade so close it on exit
   {
      if(OrderSelect(ticket,SELECT_BY_TICKET))
      {
         if(OrderType()==OP_BUY) // if a buy close at Bid
         {
            if(OrderClose(ticket,OrderLots(),Bid,10,clrNONE)) Print("Closed trade ",ticket);
            else Print("Close Error ",ticket," ",GetLastError());
         }
         else // must be a sell so close at Ask
         {
            if(OrderClose(ticket,OrderLots(),Ask,10,clrNONE)) Print("Closed trade ",ticket);
            else Print("Close Error ",ticket," ",GetLastError());
         }     
      } 
      else { Print("Can't select the ticket ",ticket," ",GetLastError() ); return; }
   }
   
   Print("OnDeinit()=",reason);
}

void OnTick()
{
   if(ticket) // got a ticket
   {
      if(OrderSelect(ticket,SELECT_BY_TICKET)) 
      {
         if(OrderCloseTime()) ticket=0; // has a close time so reset and carry on to place another trade 
         else { trailingstop(); return; } // trailing stoploss
      } 
      else { Print("Can't select the ticket ",ticket," ",GetLastError() ); return; }
   }
   
   double _entry,_stoploss,_lotsize=0; // used for risk managment   

   if(MathRand()<16384) // goes 0 to 32767
   {
      _entry=Ask;
      _stoploss=Ask-(stoploss*Point()); // now have enough to calculate lotsize
      _lotsize=calclotsize(_entry-_stoploss); // risk in price ( stoploss is below entry )      
         
      if(_lotsize==0) return; // can't place trade        
      
      ticket=OrderSend(Symbol(),OP_BUY,_lotsize,_entry,10,_stoploss,Ask+(takeprofit*Point()),"Random Buy",0,0,clrNONE);
      if(ticket==-1)
      {
         Print("Buy Error ",GetLastError());
         ticket=0;
      }
      else Print("Tickvalue=",SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE));
   }
   else
   {
      _entry=Bid;
      _stoploss=Bid+(stoploss*Point()); // now have enough to calculate lotsize
      _lotsize=calclotsize(_stoploss-_entry); // risk in price ( stoploss is above entry )      
         
      if(_lotsize==0) return; // can't place trade   
   
      ticket=OrderSend(Symbol(),OP_SELL,_lotsize,_entry,10,_stoploss,Bid-(takeprofit*Point()),"Random Sell",0,0,clrNONE);
      if(ticket==-1)
      {
         Print("Sell Error ",GetLastError());
         ticket=0;
      }
      else Print("Tickvalue=",SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE));
   }
}

// calculates a lotsize based on % risk
double calclotsize(double riskprice) // riskprice might be 0.00100 = 10 pips = 100 points = 100 ticks ( a tick is not always same as point ) 
{
   if(lotsize) return lotsize; // use fixed lotsize

   // how many ticks are risked 
   double riskticks=riskprice/SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE); // i.e. 0.00100 / 0.00001 tick size = 100 ticks, usually same as points 
   
   // tick value is amount of risk in account currency per contract ( 1.00 ) per tick
   double tickvalue=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_VALUE); // i.e. EURUSD 1.00 contract might be $1/point = $10/pip and tickvalue in GBP ~ £0.75/tick
   
   // how much cash risked
   double riskcash=AccountBalance()*riskpercent*0.01; // could use equity i.e. 0.1% of £10,000 is £10  
   
   double idealotsize=riskcash/(riskticks*tickvalue); // EURUSD example £10 / ( 100 ticks * tickvalue 0.75 ) = 0.1333 is $1.30/pip ~ £10 per 10 pips or 100 ticks
   
   // temp values
   double riskcalc=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN),tmp=0; // start usually at 0.01 
   
   while(true) // this loop breaks when it goes over the percent risk, start at typically 0.01 and go up to MAX step is usually 0.01 
   {
      if(riskcalc>idealotsize) break; // gone over ideal ?       
      if(riskcalc>SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX)) break; // gone over max ?
      tmp=riskcalc; // least value under % risk 
      riskcalc+=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP); // next step
   }
   
   Print("Ideal lotsize=",DoubleToString(idealotsize,4)," Rounded down to ",DoubleToString(tmp,2)); // show ideal size 
   
   return tmp;
}

void trailingstop() // update once per candle 
{
   if(update==iTime(NULL,0,0)) return; 
   update=iTime(NULL,0,0); // update 
   
   if(OrderSelect(ticket,SELECT_BY_TICKET)) // done already but ok 
   {
      if(OrderType()==OP_BUY)
      {
         if((Ask-OrderStopLoss())>(stoploss*Point()) ) // time to trailstoploss
         {
            if(OrderModify(ticket,0,Ask-(stoploss*Point()),OrderTakeProfit(),0,clrNONE))
               Print("New stoploss ",DoubleToString(Ask-(stoploss*Point()),Digits) );
            else
               Print("Failed to trail stop");
         }      
      }
      else // must be a sell
      {
         if((OrderStopLoss()-Bid)>(stoploss*Point()) ) // time to trailstoploss
         {
            if(OrderModify(ticket,0,Bid+(stoploss*Point()),OrderTakeProfit(),0,clrNONE))
               Print("New stoploss ",DoubleToString(Bid+(stoploss*Point()),Digits) );
            else
               Print("Failed to trail stop");
         } 
      }
   }
}