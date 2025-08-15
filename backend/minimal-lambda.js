// ITSANDBOX Minimal Lambda Backend
// Ultra-low-cost essential functions only
// Estimated cost: $0.50-2.00/month

exports.handler = async (event, context) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        const action = event.action || 'health-check';
        
        switch (action) {
            case 'health-check':
                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    body: JSON.stringify({
                        status: 'healthy',
                        timestamp: new Date().toISOString(),
                        architecture: 'ultra-low-cost',
                        estimatedMonthlyCost: '$0.50-2.00',
                        features: {
                            githubPages: 'enabled',
                            mockApi: 'enabled',
                            localStorage: 'enabled',
                            costMonitoring: 'enabled'
                        }
                    })
                };
                
            case 'system-stats':
                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Cache-Control': 'public, max-age=300'
                    },
                    body: JSON.stringify({
                        platform: 'aws-lambda',
                        architecture: 'ultra-low-cost',
                        hosting: 'GitHub Pages',
                        backend: 'Minimal Lambda',
                        database: 'LocalStorage + GitHub',
                        estimatedCosts: {
                            hosting: '$0.00 (GitHub Pages)',
                            backend: '$0.50-2.00 (Lambda)',
                            monitoring: '$0.00-1.00 (CloudWatch)',
                            total: '$0.50-3.00/month'
                        },
                        timestamp: new Date().toISOString()
                    })
                };
                
            default:
                return {
                    statusCode: 200,
                    headers: {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*'
                    },
                    body: JSON.stringify({
                        message: 'ITSANDBOX Ultra-Low-Cost Backend',
                        action: action,
                        timestamp: new Date().toISOString(),
                        cost: 'Under $5/month'
                    })
                };
        }
        
    } catch (error) {
        console.error('Error:', error);
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'Internal server error',
                message: error.message,
                timestamp: new Date().toISOString()
            })
        };
    }
};