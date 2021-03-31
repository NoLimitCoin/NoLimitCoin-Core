import React from 'react';
import { Menu, MenuItem} from "semantic-ui-react";

function Navbar(){
  return(
    <header>
      <Menu secondary>
      <MenuItem>
        <div className="inline">
        <img src="./images/NLClogo90.png" alt="quote" width="30" />
        </div>
        <div className="inline">
        <h1>No Limit Coin</h1>
        </div>
        </MenuItem>
      </Menu>  
    </header>
  );
}

export default Navbar;
