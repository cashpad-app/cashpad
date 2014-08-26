# geeky wallet

keep track of personal and group expenses, geeky style

## a short vacation story

Luca, Gabriele and Daniele go together in vacation in Milan for a few days..

    @people luca gabriele daniele

First, they buy their plane tickets, which cost 150$. Luca pays for everyone
   
    plane ticket: luca 450 -> luca gabriele daniele

Then he pays for the hotel too, but he's tired of writing all his friends names!
    
    hotel: luca 200 -> ...

They go out for dinner, this time daniele pays. Gabriele is kind of thirsty and gets an extra beer
    
    dinner: gabriele 65 -> gabriele +5 daniele luca

Or better, we know who the others are 
    
    dinner: gabriele 65 -> gabriele +5 ...

Who wants a gelato? Luca's icecream is quite expensive!
    
    ice cream: daniele 11 -> luca 5 ...

After the gelato, it's cocktails time! Daniele's turn to pay,
    
    bar: daniele 42 -> luca 14 daniele 13 gabriele 9

Woops, that doesn't add up! Daniele paid tips and taxes too, we'd better split that proportionally

    bar: daniele 42 -> luca 14 daniele 13 gabriele 9 $

Awww, much better!

It's a new day, how about remembering the date of this breakfast?
    
    2014-07-30 breakfast: luca 10

Actually that wasn't the only expense of the day, how about grouping them?

    @date 2014-07-30
      breakfast: luca 10
      coffee: daniele 7 -> gabriele daniele
      skydiving: daniele 120 -> luca gabriele

The next day luca is wandering off by himself...

    @date 2014-07-31 
    @people -luca
      having fun without luca: gabriele 15 -> daniele +4 ...
      moar fun: daniele 13

Luca is back! Time to settle up some debts

    gabriele 150 -> luca
    daniele 100 -> luca

It's the twitter era, who's up for some hashtags?

    bar #drinks: luca 20
    
    @tags #birthdayparty
      booze: daniele 30 -> luca 0
      bitches: daniele 120 -> daniele // WAIT, WAT?!

advanced stuff (work in progress)
===================================
for the brave of hearts..
- reverse (did you earn/win something instead of spending?)
  
        lottery: luca 100 <- ...
  
- ignore in cash flow
  
        * previous debt: daniele 100 -> gabro

- personal expenses
 
        pizza: luca 12 -> luca

  or create a group just for you, which you can even put in a separate file
  
      @people luca
        pizza: luca 12
      
- include multiple wallets
    
        @include summer2014.wallet
        @include http://mywebsite.com/summer2014.wallet    
