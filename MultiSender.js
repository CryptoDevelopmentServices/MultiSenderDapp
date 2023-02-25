import React, { useState } from "react";
import Web3 from "web3";
import MultiSenderABI from "./abi/MultiSenderABI.json";

const web3 = new Web3(window.ethereum);

const multiSenderContractAddress = "0x123..."; // Replace with actual contract address
const multiSenderContractABI = MultiSenderABI; // Replace with actual contract ABI

function MultiSender() {
  const [selectedToken, setSelectedToken] = useState("ETH");
  const [recipientAddresses, setRecipientAddresses] = useState(["", ""]);
  const [recipientAmounts, setRecipientAmounts] = useState(["", ""]);
  const [txHash, setTxHash] = useState("");

  async function sendTokens() {
    const contract = new web3.eth.Contract(
      multiSenderContractABI,
      multiSenderContractAddress
    );

    const recipients = recipientAddresses.filter((address) => !!address);
    const amounts = recipientAmounts
      .filter((amount) => !!amount)
      .map((amount) => web3.utils.toWei(amount.toString(), "ether"));

    if (selectedToken === "ETH") {
      await contract.methods.sendETH(recipients, amounts).send({
        from: web3.eth.defaultAccount,
        value: web3.utils.toWei(
          amounts.reduce((a, b) => Number(a) + Number(b), 0).toString(),
          "ether"
        ),
      });
    } else {
      await contract.methods
        .sendToken(selectedToken, recipients, amounts)
        .send({
          from: web3.eth.defaultAccount,
        });
    }

    setTxHash(`https://etherscan.io/tx/${tx.transactionHash}`);
  }

  return (
    <div>
      <h1>MultiSender</h1>

      <div>
        <label>Select Token:</label>
        <select value={selectedToken} onChange={(e) => setSelectedToken(e.target.value)}>
          <option value="ETH">ETH</option>
          <option value="0xabc...">Token1</option>
          <option value="0xdef...">Token2</option>
        </select>
      </div>

      <div>
        {recipientAddresses.map((_, index) => (
          <div key={index}>
            <label>Recipient #{index + 1} Address:</label>
            <input
              type="text"
              value={recipientAddresses[index]}
              onChange={(e) => {
                const newRecipientAddresses = [...recipientAddresses];
                newRecipientAddresses[index] = e.target.value;
                setRecipientAddresses(newRecipientAddresses);
              }}
            />
            <label>Recipient #{index + 1} Amount:</label>
            <input
              type="text"
              value={recipientAmounts[index]}
              onChange={(e) => {
                const newRecipientAmounts = [...recipientAmounts];
                newRecipientAmounts[index] = e.target.value;
                setRecipientAmounts(newRecipientAmounts);
              }}
            />
          </div>
        ))}
        <button onClick={() => setRecipientAddresses([...recipientAddresses, ""])}>
          Add Recipient
        </button>
      </div>

      <button onClick={sendTokens}>Send Tokens</button>

      {txHash && (
        <div>
          <label>Tx Hash:</label>
          <a href={txHash} target="_blank" rel="noreferrer">
            {txHash}
          </a>
        </div>
      )}
    </div>
  );
}

export default MultiSender;
