// Compatibilidade entre os rótulos em português e o enum payment_method do Supabase.
(function () {
  const applyPaymentValues = () => {
    const sale = document.getElementById('salePayment');
    if (sale) {
      const values = ['pix', 'cash', 'credit', 'other'];
      Array.from(sale.options).forEach((opt, i) => { if (values[i]) opt.value = values[i]; });
    }

    const expense = document.getElementById('expensePayment');
    if (expense) {
      const values = ['pix', 'cash', 'credit', 'bank_transfer'];
      Array.from(expense.options).forEach((opt, i) => { if (values[i]) opt.value = values[i]; });
    }
  };

  document.addEventListener('DOMContentLoaded', applyPaymentValues);
  window.addEventListener('load', applyPaymentValues);
  setTimeout(applyPaymentValues, 1000);
})();
