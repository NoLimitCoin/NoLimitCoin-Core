import React, { useEffect, useState} from 'react';
import Web3 from 'web3';
import NLC from '../abis/NLC.json';
import { Segment, Input, Form, Button, Loader } from 'semantic-ui-react';

function Main(){
    const [inp, setInp] = useState(0);
    const [nlc, setNlc] = useState({});
    const [loading,setLoading] = useState(false);
    const [acc,setAcc] = useState("");
    
    async function loadBlockchainData(){
        if(typeof window.ethereum!=='undefined'){
            const web3 = new Web3(window.ethereum);
            const netId = await web3.eth.net.getId();
            const accounts = await web3.eth.getAccounts();

            //load contracts
            const nlcData = NLC.networks[netId];
      
            //load account
            if(typeof accounts[0] !=='undefined'){
                setAcc(accounts[0]);
                if(nlcData) {
                    const nlcd = new web3.eth.Contract(NLC.abi, nlcData.address);
                    setNlc(nlcd);
                } else {
                    window.alert('NLC contract not deployed to detected network.');
                }
            } else {
              window.alert('Please login with MetaMask First');
            }
      
        } else {
            window.alert('Please install MetaMask');
        }
        
    }

    useEffect(() => {  
        loadBlockchainData();
    },[]) 

    function handleChange(event){
        setInp(event.target.value);
    }

    function burnSupply(){
    
        setLoading(true);
          //To mint 1 NLC token, multiply amount with 10^8 

          const NLCAmount = inp*100000000;  
          nlc.methods.burnSupply(NLCAmount).send({from:acc})
          .once('confirmation', (confirmation, hash) => {
            window.alert("Transaction successful. Tx hash: "+ hash.transactionHash);
            setLoading(false);
          })
          .on('error', (error) => {
              window.alert("Transaction failed. Try again!");
              setLoading(false);
          });
       
      }
    
  return(
    <div className="main">
      <div className="burn">
      <Segment basic textAlign="center">
            <Form>
            <Form.Field>
            <Input placeholder=" Add Token Amount " onChange={handleChange} size="massive" fluid />
            </Form.Field>
            <Form.Field>
            {loading?<Loader active inline='centered' />:
            <Button color="red" size="big" fluid onClick={burnSupply} >Burn Tokens</Button>
            }
            </Form.Field>
            </Form>
      </Segment>
      </div>
    </div>  
  );

}

export default Main;