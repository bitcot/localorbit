class DeliveryNotesController < ApplicationController

	before_action :find_cart

	def index
		# TODO decide if there is an indexed display, and if so where (at first no)
		#@delivery_notes = @cart.delivery_notes.visible.alphabetical_by_supplier_org
	end

	def new
		dn = DeliveryNote.where(cart_id:find_cart,supplier_org:params[:supplier])
		if dn.any?
			redirect_to edit_delivery_note_path(dn.first.id)
		end
	end

	def create
		@cart = Cart.find(find_cart)
		@buyer_org = current_organization

		@delivery_note = DeliveryNote.create(delivery_note_params)
		if @delivery_note.persisted?
			redirect_to "/cart" # cart path
		else
			render :new # need to pass the correct parameters here
			# with error flash
		end

	end

	def edit
		@delivery_note = DeliveryNote.find(params[:id])
	end

	def update
		@delivery_note = DeliveryNote.find(params[:id])
		if @delivery_note.update_attributes(delivery_note_params) # does that exist here
			redirect_to delivery_notes_path(@cart.id) # each cart has only one buyer org. this could be a problem though, not set upu for it anymore
		else # probably instead here shoudl be updating the attrs
			render :edit # hm, may not use this ultimately
		end
	end

	def destroy
		DeliveryNote.soft_delete(params[:id])
		redirect_to delivery_notes_path(@cart.id)
	end

	private

	def delivery_note_params
		params.require(:delivery_note).permit(:note,:supplier_org,:buyer_org,:cart_id)
	end

	def find_cart
		@cart_id = current_cart.id # this should exist in valid session for notes
	end
end