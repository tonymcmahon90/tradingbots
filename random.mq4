// simplest random forex robot with reasonable error checking 26th June 2023 
// this robot opens a trade on a chart regardless of any other trades, it gets the ticket number of the random buy or sell trade and resets when the order is closed

#property strict // new MQL4

// some brokers have minimum 0.02 others might be spread betting hence 0.10 = 10p/pip 
input double lotsize=0.02; 

int ticket; // got from OrderSend() otherwise 0 

int OnInit()
{
   MathSrand(GetTickCount()); // ms since system start
   ticket=0;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(ticket) // got an open trade so close it on exit
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
         if(OrderCloseTime()) ticket=0; // has a close time so reset
         else return; 
      } 
      else { Print("Can't select the ticket ",ticket," ",GetLastError() ); return; }
   }

   if(MathRand()<16384) // goes 0 to 32767
   {
      ticket=OrderSend(Symbol(),OP_BUY,lotsize,Ask,10,Ask-(100*Point()),Ask+(100*Point()),NULL,0,0,clrNONE);
      if(ticket==-1)
      {
         Print("Buy Error ",GetLastError());
         ticket=0;
      }
   }
   else
   {
      ticket=OrderSend(Symbol(),OP_SELL,lotsize,Bid,10,Bid+(100*Point()),Bid-(100*Point()),NULL,0,0,clrNONE);
      if(ticket==-1)
      {
         Print("Sell Error ",GetLastError());
         ticket=0;
      }
   }
}