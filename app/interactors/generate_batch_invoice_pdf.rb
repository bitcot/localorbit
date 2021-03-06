class GenerateBatchInvoicePdf
  include Interactor

  def perform
    BatchInvoiceUpdater.start_generation!(batch_invoice)

    completed_count = 0
    invoice_tempfiles = []
    batch_invoice.orders.each do |order|
      begin
        tempfile = Tempfile.new("tmp-invoice-#{order.order_number}")

        pdf_result = Invoices::InvoicePdfGenerator.generate_pdf(request:request, order:order, path:tempfile.path)

        invoice_tempfiles << tempfile

      rescue StandardError => e
        BatchInvoiceUpdater.record_error!(batch_invoice,
                                          task: "Generating invoice PDF",
                                          message: "Unexpected exception in InvoicePdfGenerator",
                                          exception: e,
                                          order: order)
      end

      completed_count += 1
      BatchInvoiceUpdater.update_generation_progress!(batch_invoice, completed_count: completed_count)
    end

    merged_pdf = GhostscriptWrapper.merge_pdf_files(invoice_tempfiles)
    invoice_tempfiles.each { |file| file.unlink }

    BatchInvoiceUpdater.complete_generation!(batch_invoice, pdf: merged_pdf, pdf_name: "invoices.pdf")

  rescue StandardError => e
    BatchInvoiceUpdater.record_error!(batch_invoice,
                                      task: "Generating batch invoice PDF",
                                      message: "Unexpected exception while processing and merging invoice PDFs",
                                      exception: e)
    BatchInvoiceUpdater.fail_generation!(batch_invoice)
  end

  #
  # Helpers:
  #

  class BatchInvoiceUpdater
    class << self
      def start_generation!(batch_invoice)
        batch_invoice.update!(
          generation_progress: 0.0,
          generation_status: BatchInvoice::GenerationStatus::Generating)
      end

      def update_generation_progress!(batch_invoice, completed_count:)
        batch_invoice.update!(
          generation_progress: 1.0 * completed_count / batch_invoice.orders.count)
      end

      def complete_generation!(batch_invoice, pdf:, pdf_name:)
        batch_invoice.pdf = pdf
        batch_invoice.pdf.name = pdf_name
        batch_invoice.generation_progress = "1.0".to_d
        batch_invoice.generation_status = BatchInvoice::GenerationStatus::Complete
        batch_invoice.save!
      end

      def fail_generation!(batch_invoice)
        batch_invoice.update!(
          generation_status: BatchInvoice::GenerationStatus::Failed
        )
      end

      def record_error!(batch_invoice, task:, message:, order: nil, exception: nil)
        batch_invoice.batch_invoice_errors.create(
          task: task,
          message: message,
          exception: exception.inspect,
          backtrace: exception.backtrace.join("\n"),
          order: order)

        Rollbar.error(exception)
      end
    end
  end
end
