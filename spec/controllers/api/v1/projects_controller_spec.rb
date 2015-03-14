require 'spec_helper'
require 'api/v1/projects_controller'

describe Api::V1::ProjectsController do

  before(:each) { request.headers['Accept'] = "application/json" }

  describe "GET #show" do
    before(:each) do
      @project = FactoryGirl.create :project
      get :show, id: @project.id, format: :json
    end

    it "returns the information about a reporter on a hash" do
      project_response = JSON.parse(response.body, symbolize_names: true)
      expect(project_response[:title]).to eql @project.title
    end

    it { should respond_with 200 }
  end

  describe "PUT #update" do
    before(:each) do
      Project.stub(:valid?).and_return(true)
      Project.any_instance.stub(:valid?).and_return(true)
      User.stub(:valid?).and_return(true)
      User.any_instance.stub(:valid?).and_return(true)
    end
    
    it "should update the project when I own it and it exists" do
      user = User.create(email: "steven@berk.edu")
      proj = Project.create(title: "Test proj", owner:user.id)
      Project.any_instance.should_receive(:update_attributes)
      Api::V1::ProjectsController.any_instance.stub(:getCurrentUser).and_return(user)
      put :update, { project_params: proj.attributes, id:proj.id }, format: :json
      expect(response.status).to eq(204)
    end

    it "should redirect when I am not logged in" do
      proj = Project.create(title: "Test proj")
      Api::V1::ProjectsController.any_instance.stub(:getCurrentUser).and_return(nil)
      put :update, { project_params: proj.attributes, id:proj.id}, format: :json
      expect(response.status).to eq(301)
    end

    it "should reject the request when I don't own the project" do
      user = User.create(email: "steven@berk.edu")
      proj = Project.create(title: "Test proj", owner:(user.id+1))
      Api::V1::ProjectsController.any_instance.stub(:getCurrentUser).and_return(user)
      put :update, { project_params: proj.attributes, id:proj.id }, format: :json
      expect(response.status).to eq(401)
    end    

    it "should reject the request when the project doesn't exist" do
      user = User.create(email: "steven@berk.edu")
      proj = Project.create(title: "Test proj", owner:user.id)
      Api::V1::ProjectsController.any_instance.stub(:getCurrentUser).and_return(user)
      put :update, { project_params: proj.attributes, id:(proj.id+1) }, format: :json
      expect(response.status).to eq(404)
    end


  end


  describe "POST #create" do

    context "when is successfully created" do
      before(:each) do
        @project_attributes = FactoryGirl.attributes_for :project
        post :create, { project: @project_attributes }, format: :json
      end

      it "renders the json representation for the project record just created" do
        project_response = JSON.parse(response.body, symbolize_names: true)
        expect(project_response[:title]).to eql @project_attributes[:title]
      end

      it { should respond_with 201 }
    end

    context "when is not created" do
      before(:each) do
        #notice I'm not including the title
        @invalid_project_attributes = { note: "example_note", is_public: 0 }
        post :create, { project: @invalid_project_attributes }, format: :json
      end

      it "renders an errors json" do
        project_response = JSON.parse(response.body, symbolize_names: true)
        expect(project_response).to have_key(:errors)
      end

      it "renders the json errors on why the project could not be created" do
        project_response = JSON.parse(response.body, symbolize_names: true)
        expect(project_response[:errors][:title]).to include "can't be blank"
      end

      it { should respond_with 422 }
    end
  end

  describe "DELETE #destroy" do
    before(:each) do
      @project = FactoryGirl.create :project
      delete :destroy, { id: @project.id }, format: :json
    end
    
    it { should respond_with 204 }
    
  end

  describe "GET #index" do
    before(:each) do
      Project.stub(:valid?).and_return(true)
      Project.any_instance.stub(:valid?).and_return(true)
      User.stub(:valid?).and_return(true)
      User.any_instance.stub(:valid?).and_return(true)
    end

    it "Should show all projects belonging to user if logged in" do
      user = User.create(email: "jwang@berk.edu")
      Api::V1::ProjectsController.any_instance.stub(:getCurrentUser).and_return(user)
      proj1 = Project.create(title: "user public", owner:user.id, is_public: 1)
      proj2 = Project.create(title: "user private", owner:user.id, is_public: 0)
      proj3 = Project.create(title: "nonuser public", owner:user.id+1, is_public: 1)
      proj4 = Project.create(title: "nonuser private", owner:user.id+1, is_public: 0)
      get :index, {user_id: user.id}, format: :json
      project_response = JSON.parse(response.body, symbolize_names: true)
      expect(project_response.length).to eq(2)
      expect(project_response[0][:title]).to eq("user public")
      expect(project_response[1][:title]).to eq("user private")
    end

    it "Should show only public projects if user not logged in" do
      user = User.create(email: "jwang@berk.edu")
      Api::V1::ProjectsController.any_instance.stub(:getCurrentUser).and_return(nil)
      proj1 = Project.create(title: "user public", owner:user.id, is_public: 1)
      proj2 = Project.create(title: "user private", owner:user.id, is_public: 0)
      proj3 = Project.create(title: "nonuser public", owner:user.id+1, is_public: 1)
      proj4 = Project.create(title: "nonuser private", owner:user.id+1, is_public: 0)
      get :index, {user_id: user.id}, format: :json
      project_response = JSON.parse(response.body, symbolize_names: true)
      expect(project_response.length).to eq(1)
      expect(project_response[0][:title]).to eq("user public")
    end

  end

  # describe "PUT/PATCH #update" do

  #   context "when is successfully updated" do
  #     before(:each) do
  #       @project = FactoryGirl.create :project
  #       patch :update, { id: @project.id,
  #                        project: { title: "new title" } }, format: :json
  #     end

  #     it "renders the json representation for the updated project" do
  #       project_response = JSON.parse(response.body, symbolize_names: true)
  #       expect(project_response[:title]).to eql "new title"
  #     end

  #     it { should respond_with 200 }
  #   end

  #   context "when is not created" do
  #     before(:each) do
  #       @project = FactoryGirl.create :project
  #       patch :update, { id: @project.id,
  #                        project: { title: "bad title" } }, format: :json
  #     end

  #     it "renders an errors json" do
  #       project_response = JSON.parse(response.body, symbolize_names: true)
  #       expect(project_response).to have_key(:errors)
  #     end

  #     it "renders the json errors on why the project could not be created" do
  #       project_response = JSON.parse(response.body, symbolize_names: true)
  #       expect(project_response[:errors][:title]).to include "is invalid"
  #     end

  #     it { should respond_with 422 }
  #   end
  # end

end