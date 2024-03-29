# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::Filters::KeywordsController do
  render_views

  let(:user)         { Fabricate(:user) }
  let(:token)        { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:filter)       { Fabricate(:custom_filter, account: user.account) }
  let(:other_user)   { Fabricate(:user) }
  let(:other_filter) { Fabricate(:custom_filter, account: other_user.account) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    let(:scopes) { 'read:filters' }
    let!(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    it 'returns http success' do
      get :index, params: { filter_id: filter.id }
      expect(response).to have_http_status(200)
      expect(body_as_json)
        .to contain_exactly(
          include(id: keyword.id.to_s)
        )
    end

    context "when trying to access another's user filters" do
      it 'returns http not found' do
        get :index, params: { filter_id: other_filter.id }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST #create' do
    let(:scopes)    { 'write:filters' }
    let(:filter_id) { filter.id }

    before do
      post :create, params: { filter_id: filter_id, keyword: 'magic', whole_word: false }
    end

    it 'creates a filter', :aggregate_failures do
      expect(response).to have_http_status(200)

      json = body_as_json
      expect(json[:keyword]).to eq 'magic'
      expect(json[:whole_word]).to be false

      filter = user.account.custom_filters.first
      expect(filter).to_not be_nil
      expect(filter.keywords.pluck(:keyword)).to eq ['magic']
    end

    context "when trying to add to another another's user filters" do
      let(:filter_id) { other_filter.id }

      it 'returns http not found' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'GET #show' do
    let(:scopes)  { 'read:filters' }
    let(:keyword) { Fabricate(:custom_filter_keyword, keyword: 'foo', whole_word: false, custom_filter: filter) }

    before do
      get :show, params: { id: keyword.id }
    end

    it 'responds with the keyword', :aggregate_failures do
      expect(response).to have_http_status(200)

      json = body_as_json
      expect(json[:keyword]).to eq 'foo'
      expect(json[:whole_word]).to be false
    end

    context "when trying to access another user's filter keyword" do
      let(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: other_filter) }

      it 'returns http not found' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'PUT #update' do
    let(:scopes)  { 'write:filters' }
    let(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    before do
      get :update, params: { id: keyword.id, keyword: 'updated' }
    end

    it 'updates the keyword', :aggregate_failures do
      expect(response).to have_http_status(200)

      expect(keyword.reload.keyword).to eq 'updated'
    end

    context "when trying to update another user's filter keyword" do
      let(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: other_filter) }

      it 'returns http not found' do
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:scopes)  { 'write:filters' }
    let(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: filter) }

    before do
      delete :destroy, params: { id: keyword.id }
    end

    it 'destroys the keyword', :aggregate_failures do
      expect(response).to have_http_status(200)

      expect { keyword.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    context "when trying to update another user's filter keyword" do
      let(:keyword) { Fabricate(:custom_filter_keyword, custom_filter: other_filter) }

      it 'returns http not found' do
        expect(response).to have_http_status(404)
      end
    end
  end
end
