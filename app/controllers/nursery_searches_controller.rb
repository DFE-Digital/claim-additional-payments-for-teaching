class NurserySearchesController < ApplicationController
  def create
    @nurseries = [
      {id: "1", name: "Sunshine Day Nursery", address: "123 Oak Street, London, E1 1AA"},
      {id: "2", name: "Little Stars Childcare", address: "45 Maple Road, Manchester, M1 2BB"},
      {id: "3", name: "Happy Days Nursery", address: "78 Elm Avenue, Birmingham, B1 3CC"},
      {id: "4", name: "Tiny Tots Preschool", address: "90 Pine Lane, Leeds, LS1 4DD"},
      {id: "5", name: "Rainbow Kids Nursery", address: "12 Cedar Close, Bristol, BS1 5EE"}
    ]
    render json: {data: @nurseries}
  end
end
