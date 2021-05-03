# ERC20IntegratedERC721

There are two contracts: 
  ERC20.sol which creates RCED tokens, and
  ERC721.sol which created CRPTCF tokens.
  
Steps to deploy both contracts on Remix and MetaMask:

  First compile and deploy ERC20.sol from any account. 
  Note the CONTRACT ADDRESS where it is deployed and the OWNER, they will be needed again.
  Once deployed, contract OWNER should have 10**24 RCED tokens in his account.
  
  Now compile ERC721.sol. 
  Notice that for deployment, an address token field is required to be filled.
  Enter the ERC20.sol CONTRACT ADDRESS from above, and deploy this contract using a different account. 
  This allows our RCED tokens to be used in our ERC721.sol contract.
  Note the CONTRACT ADDRESS of this contract as well.
  
  Now that we have both contracts deployed, we want to transfer some or all of our RCED tokens from ERC20 OWNER to ERC721 CONTRACT ADDRESS.
  To do this, go to deployed ERC20 contract and call TRANSFER function from OWNER account. 
  Enter RECIPIENT as ERC721 CONTRACT ADDRESS, and AMOUNT as any amount upto 10**24.
  This will transfer AMOUNT RCED tokens to our ERC721 CONTRACT ADDRESS.
  
  This allows our users to exchange their ETH with RCED tokens. 
  To do that, choose any account, enter VALUE and run buyRicheduToken() from ERC721 contract.
  Wei/Ether sent by the user will be exchanged with equivalent RCED tokens.
  
  To allow our ERC721 contract to spend RCED tokens from a user's account, we need to approve it as a spender.
  To do this, choose the account which executed buyRicheduToken() function. 
  Go to the deployed ERC20 contract and find APPROVE.
  Enter ERC721 CONTRACT ADDRESS as the SPENDER and a large amount, e.g., 10**24 as the AMOUNT and execute. Allow when asked.
  
  Now, transactions are possible in both directions, i.e, from user to ERC721 CONTRACT and vice-versa.
  Execute any function in ERC721.sol, they should all be working without errors.
