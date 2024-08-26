require 'rails_helper'

describe AuthenticationTokenService , type: :request do
    let(:token) {described_class.encode(1598)}
    describe '.encode' do
        it 'returns an authentication token' do
            decoded_token = JWT.decode( 
                token, 
                described_class::HMAC_SECRET, 
                true, 
                { algorithm: described_class::ALGORITHM_TYPE }
                )

            expect(decoded_token).to eq(
            [                
                {"editor_id" => 1598},
                {"alg" => "HS256"}
            ]
            )                
        end
    end
end