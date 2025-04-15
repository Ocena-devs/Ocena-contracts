# DexManager: Withdrawing Raised POL (MATIC)  

This guide explains how to withdraw raised POL (MATIC) from the `DexManager` contract using PolygonScan.  

---

## **Prerequisites**  
- You must be the **contract owner** (only the owner can call `withdrawRaisedPOL`).  
- Ensure the contract has a sufficient MATIC balance.  

---

## **Step-by-Step Guide**  

### **1. Access the Contract on PolygonScan**  
1. Go to your contract on [Polygonscan]([https://polygonscan.com/](https://polygonscan.com/address/0x90b2FbaC2424DF4BfeD42eB681273b4615880432)).  
2. Navigate to the **"Contract"** tab → **"Write Contract"**.  
3. Connect your wallet (must be the owner’s wallet).  

### **2. Call `withdrawRaisedPOL`**  
- **Function:** `withdrawRaisedPOL(uint256 amount)`  
- **Input:**  
  - **`amount`**: The amount to withdraw **in wei** (1 MATIC = `10^18` wei).  

#### **Example Values:**  
| MATIC Amount | Wei Value (Input) |  
|--------------|-------------------|  
| 1 MATIC      | `1000000000000000000` |  
| 0.5 MATIC    | `500000000000000000` |  
| 10 MATIC     | `10000000000000000000` |  

### **3. Submit the Transaction**  
1. Enter the **wei amount** in the input field.  
2. Click **"Write"** and confirm the transaction in MetaMask/your wallet.  

---
