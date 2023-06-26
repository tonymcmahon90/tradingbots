#property strict

input double lotsize=0.02;

int ticket;

int OnInit()
{
   MathSrand(GetTickCount()); // ms since system start
   ticket=0;
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int reason)
{
   if(ticket)
   {
      if(OrderSelect(ticket,SELECT_BY_TICKET))
      {
         if(OrderType()==OP_BUY) // if a buy close at Bid
         {
            if(OrderClose(ticket,OrderLots(),Bid,10,clrNONE)) Print("Closed trade");
            else Print("Close Error ",GetLastError());
         }
         else // must be a sell so close at Ask
         {
            if(OrderClose(ticket,OrderLots(),Ask,10,clrNONE)) Print("Closed trade");
            else Print("Close Error ",GetLastError());
         }     
      } 
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