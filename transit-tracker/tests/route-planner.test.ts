import { 
  Clarinet,
  Tx,
  Chain,
  Account,
  types 
} from 'https://deno.land/x/clarinet@v1.0.5/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that only contract owner can set provider status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    const user2 = accounts.get('wallet_2')!;

    // Test setting provider status as contract owner
    let block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-provider-status',
        [
          types.principal(user1.address),  // provider
          types.bool(true)                 // active
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, '(ok true)');

    // Test setting provider status as non-owner (should fail)
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-provider-status',
        [
          types.principal(user2.address),  // provider
          types.bool(true)                 // active
        ],
        user1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, '(err u100)');  // err-owner-only
  }
});

Clarinet.test({
  name: "Ensure that only authorized providers can add routes",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const provider = accounts.get('wallet_1')!;
    const user = accounts.get('wallet_2')!;

    // First set the provider as authorized
    let block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-provider-status',
        [
          types.principal(provider.address),  // provider
          types.bool(true)                    // active
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Test adding a route as an authorized provider
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'add-route',
        [
          types.ascii('STOP001'),                                          // from-stop
          types.ascii('STOP002'),                                          // to-stop
          types.list([types.ascii('STOP001'), types.ascii('STOP002')]),    // route-steps
          types.uint(600)                                                  // estimated-time (10 minutes)
        ],
        provider.address
      )
    ]);
    
    // Should succeed since provider is authorized
    assertEquals(block.receipts[0].result.startsWith('(ok '), true);
    
    // Test adding a route as unauthorized user
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'add-route',
        [
          types.ascii('STOP002'),                                          // from-stop
          types.ascii('STOP003'),                                          // to-stop
          types.list([types.ascii('STOP002'), types.ascii('STOP003')]),    // route-steps
          types.uint(300)                                                  // estimated-time (5 minutes)
        ],
        user.address
      )
    ]);
    
    // Should fail since user is not authorized
    assertEquals(block.receipts[0].result, '(err u103)');  // err-unauthorized
  }
});

Clarinet.test({
  name: "Ensure that route queries require payment",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const provider = accounts.get('wallet_1')!;
    const user = accounts.get('wallet_2')!;
    
    // First set the provider as authorized
    let block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-provider-status',
        [
          types.principal(provider.address),  // provider
          types.bool(true)                    // active
        ],
        deployer.address
      )
    ]);
    
    // Set query cost to 1 STX
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-query-cost',
        [types.uint(1000000)],  // 1 STX in microSTX
        deployer.address
      )
    ]);
    
    // Add a route
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'add-route',
        [
          types.ascii('STOP001'),                                          // from-stop
          types.ascii('STOP002'),                                          // to-stop
          types.list([types.ascii('STOP001'), types.ascii('STOP002')]),    // route-steps
          types.uint(600)                                                  // estimated-time (10 minutes)
        ],
        provider.address
      )
    ]);
    
    // Query the route (should require payment)
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'query-route',
        [
          types.ascii('STOP001'),  // from-stop
          types.ascii('STOP002')   // to-stop
        ],
        user.address
      )
    ]);
    
    // Should return the route since payment is automatically handled in Clarinet tests
    assertEquals(block.receipts[0].result.startsWith('(ok '), true);
    
    // Verify that STX transfer happened
    assertEquals(block.receipts[0].events[0].stx_transfer.amount, 1000000); // 1 STX transferred
    assertEquals(block.receipts[0].events[0].stx_transfer.recipient, deployer.address);
    assertEquals(block.receipts[0].events[0].stx_transfer.sender, user.address);
  }
});

Clarinet.test({
  name: "Ensure route hash verification works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Generate a route hash
    const hashResult = chain.callReadOnlyFn(
      'route-planner',
      'hash-route',
      [
        types.list([types.ascii('STOP001'), types.ascii('STOP002')]),  // stops
        types.uint(600)                                                // time
      ],
      deployer.address
    );
    
    // Verify the hash is a buffer of the correct length (32 bytes for SHA-256)
    const hashValue = hashResult.result;
    assertEquals(hashValue.type, 'buffer');
    assertEquals(hashValue.buffer.length, 32);
  }
});
import { 
  Clarinet,
  Tx,
  Chain,
  Account,
  types 
} from 'https://deno.land/x/clarinet@v1.0.5/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensure that only contract owner can set provider status",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const user1 = accounts.get('wallet_1')!;
    const user2 = accounts.get('wallet_2')!;

    // Test setting provider status as contract owner
    let block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-provider-status',
        [
          types.principal(user1.address),  // provider
          types.bool(true)                 // active
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, '(ok true)');

    // Test setting provider status as non-owner (should fail)
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-provider-status',
        [
          types.principal(user2.address),  // provider
          types.bool(true)                 // active
        ],
        user1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.receipts[0].result, '(err u100)');  // err-owner-only
  }
});

Clarinet.test({
  name: "Ensure that only authorized providers can add routes",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const provider = accounts.get('wallet_1')!;
    const user = accounts.get('wallet_2')!;

    // First set the provider as authorized
    let block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-provider-status',
        [
          types.principal(provider.address),  // provider
          types.bool(true)                    // active
        ],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(ok true)');
    
    // Test adding a route as an authorized provider
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'add-route',
        [
          types.ascii('STOP001'),                                          // from-stop
          types.ascii('STOP002'),                                          // to-stop
          types.list([types.ascii('STOP001'), types.ascii('STOP002')]),    // route-steps
          types.uint(600)                                                  // estimated-time (10 minutes)
        ],
        provider.address
      )
    ]);
    
    // Should succeed since provider is authorized
    assertEquals(block.receipts[0].result.startsWith('(ok '), true);
    
    // Test adding a route as unauthorized user
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'add-route',
        [
          types.ascii('STOP002'),                                          // from-stop
          types.ascii('STOP003'),                                          // to-stop
          types.list([types.ascii('STOP002'), types.ascii('STOP003')]),    // route-steps
          types.uint(300)                                                  // estimated-time (5 minutes)
        ],
        user.address
      )
    ]);
    
    // Should fail since user is not authorized
    assertEquals(block.receipts[0].result, '(err u103)');  // err-unauthorized
  }
});

Clarinet.test({
  name: "Ensure that route queries require payment",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const provider = accounts.get('wallet_1')!;
    const user = accounts.get('wallet_2')!;
    
    // First set the provider as authorized
    let block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-provider-status',
        [
          types.principal(provider.address),  // provider
          types.bool(true)                    // active
        ],
        deployer.address
      )
    ]);
    
    // Set query cost to 1 STX
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'set-query-cost',
        [types.uint(1000000)],  // 1 STX in microSTX
        deployer.address
      )
    ]);
    
    // Add a route
    block = chain.mineBlock([
      Tx.contractCall(
        'route-planner',
        'add-route',
        [
          types.ascii('STOP001'),                                          // from-stop
          types.ascii('STOP002'),                                          // to-stop
          types.list([types.ascii('STOP001
