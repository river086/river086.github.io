# Stock Feature Testing Guide

## Overview
This document describes the unit testing setup for the stock loading functionality in SimLifeGame.

## Test Files

### Main Test Suite
- **`stock-test.html`** - Complete test suite with UI for testing stock functionality
- **`test-data/`** - Directory containing mock XML data for testing

### Test Data Files
- **`test-data/mock-aapl.xml`** - Sample AAPL stock data for testing
- **`test-data/mock-msft.xml`** - Sample MSFT stock data for testing

## Running Tests

### Browser-based Testing
1. Open `stock-test.html` in a web browser
2. Click "Run All Tests" to execute the complete test suite
3. Individual test categories can be run separately using the specific buttons

### Test Categories

#### 1. XML Loading Tests
- Tests the `loadIndividualStockXML()` function
- Verifies XML parsing and data extraction
- Checks error handling for missing files

#### 2. Price Retrieval Tests  
- Tests the `getStockPrice()` method
- Verifies correct price retrieval from different data sources
- Tests handling of missing stock data

#### 3. Fallback Hierarchy Tests
- Tests the priority system: XML data → Legacy data → Mock data
- Verifies each fallback level works correctly
- Tests graceful degradation when data sources are unavailable

#### 4. Mock Generation Tests
- Tests the `generateMockStockPrices()` function
- Verifies real XML data is used instead of generating mock prices
- Tests mock generation for stocks without XML data

## Test Structure

### StockTestSuite Class
The main test class that contains:

```javascript
class StockTestSuite {
    constructor()                    // Initialize test suite
    setupTestGame()                  // Create minimal game instance for testing
    createMockXMLResponse()          // Generate mock XML responses
    testLoadIndividualStockXML()     // Test XML loading functionality
    testGetStockPrice()              // Test price retrieval
    testFallbackHierarchy()          // Test fallback logic
    testMockGeneration()             // Test mock price generation
    displayResults()                 // Display test results in UI
}
```

### Mock Data System
Tests use a mock fetch system to simulate XML file loading:

```javascript
window.fetch = async (url) => {
    const symbol = url.split('/')[1]?.split('.')[0]?.toUpperCase();
    if (mockData[symbol]) {
        return {
            ok: true,
            text: async () => this.createMockXMLResponse(symbol, mockData[symbol])
        };
    }
    return { ok: false };
};
```

## Expected Results

### Successful Test Run
- All tests should pass (green indicators)
- XML data loading should work correctly
- Price retrieval should follow the correct fallback hierarchy
- Mock generation should prefer real data over generated data

### Common Issues
1. **CORS errors** - Make sure to serve files from a web server, not file:// protocol
   - Use `python -m http.server 8000` or similar to serve files locally
   - Access via `http://localhost:8000/stock-test.html` instead of opening directly
2. **Missing game.js** - Ensure the main game file is in the same directory
3. **Mock data format** - Verify XML structure matches expected format
4. **Stock XML files not loading** - If running from file:// protocol, the game will gracefully fall back to embedded mock data

### Running with Local Server
To properly test the XML loading functionality:

```bash
# Navigate to the game directory
cd /path/to/SimLifeGame

# Start a local web server
python -m http.server 8000

# Open in browser
# Navigate to http://localhost:8000/stock-test.html
```

This ensures the Stocks/*.xml files can be properly loaded and tested.

## Adding New Tests

To add new test cases:

1. Add a new test method to `StockTestSuite`
2. Follow the existing pattern of returning an array of test results
3. Add a button to the UI to run the new test
4. Update the `runIndividualTest()` function to handle the new test

### Test Result Format
```javascript
{
    name: "Test description",
    pass: boolean,
    details: "Additional information about the test result"
}
```

## Integration with Main Game

The test suite creates a minimal `SimLifeGame` instance with:
- Basic game state (year, month, portfolio)
- Stock-related properties (stockPricesFromXML, aaplPrices, stockPrices)
- All necessary methods for stock functionality

This ensures tests run against the actual game code without requiring a full game initialization.