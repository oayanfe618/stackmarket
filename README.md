```markdown
# StackMarket - Decentralized Marketplace

A decentralized peer-to-peer marketplace smart contract built on the Stacks blockchain using Clarity.

## Overview

StackMarket is a trustless marketplace where sellers can list items and buyers can purchase them through an escrow-based system. The contract handles payments, order management, refunds, and seller ratings.

## Features

- **Item Listing**: Sellers can list items with title, description, price, and stock quantity
- **Purchase System**: Buyers can purchase items with automatic stock management
- **Escrow Protection**: Payments are held in escrow until buyer confirms receipt
- **Refund Policy**: Buyers can request refunds before order confirmation
- **Seller Ratings**: Buyers can rate sellers (1-5 stars) after successful purchases
- **Sales Tracking**: Contract tracks total sales and marketplace activity

## Core Functions

### Seller Functions
- `list-item` - List a new item for sale
- `get-item` - View item details

### Buyer Functions
- `buy-item` - Purchase an item (creates escrow order)
- `confirm-order` - Release payment to seller after receiving item
- `refund-order` - Request refund before order confirmation
- `rate-seller` - Rate seller after confirmed purchase (1-5 stars)

### View Functions
- `get-item` - Retrieve item details by ID
- `get-order` - Retrieve order details by ID
- `get-seller-rating` - Get seller's average rating
- `get-total-sales` - Get total marketplace sales

## Data Structures

### Items
```
{
  seller: principal,
  title: string (64 chars max),
  description: string (256 chars max),
  price: uint (in microSTX),
  stock: uint,
  active: bool
}
```

### Orders
```
{
  buyer: principal,
  item-id: uint,
  amount: uint (in microSTX),
  confirmed: bool,
  refunded: bool
}
```

### Ratings
```
{
  total-rating: uint,
  num-ratings: uint
}
```

## Error Codes

| Code | Error | Description |
|------|-------|-------------|
| 100 | NOT_FOUND | Item or order not found |
| 101 | INVALID_AMOUNT | Invalid price, quantity, or amount |
| 102 | NOT_SELLER | Only seller can perform this action |
| 103 | NOT_BUYER | Only buyer can perform this action |
| 104 | ALREADY_COMPLETED | Order already completed |
| 105 | REFUND_NOT_ALLOWED | Refund conditions not met |
| 106 | ALREADY_LISTED | Item already listed |
| 107 | NO_FUNDS | Insufficient funds |

## Transaction Flow

1. **Seller lists item** → Item is stored in `items` map
2. **Buyer purchases item** → Payment locked in escrow, order created
3. **Buyer confirms order** → Payment released to seller
4. **Buyer rates seller** → Seller rating updated
5. *(Alternative)* **Buyer requests refund** → Payment returned to buyer

## Installation & Testing

```bash
# Deploy to testnet
clarinet contract deploy

# Run tests
clarinet test

# Check contract syntax
clarinet check
```

## Security Considerations

- Escrow-based payment system prevents fraud
- Only buyers can confirm orders and receive refunds
- Only sellers receive payment confirmation
- Rating system only available after confirmed purchases
- All transactions require proper authorization

## Future Enhancements

- Multi-item orders support
- Dispute resolution system
- Commission/fee structure for marketplace
- Category and search functionality
- Seller reputation metrics
- Time-based escrow release
---

**Status**: Ready for deployment ✅
